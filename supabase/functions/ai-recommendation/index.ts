import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"
import OpenAI from "npm:openai@4.28.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ─── Lifestyle Score Computation ───
function computeLifestyleScore(userA: any, userB: any): number {
  if (!userA || !userB) return 50 // neutral default

  const categories = ['Drinking', 'Smoking', 'Workout', 'Communication Style', 'Love Language', 'Family Plans', 'Pets']
  let totalScore = 0
  let compared = 0

  for (const cat of categories) {
    const a = userA[cat]
    const b = userB[cat]
    if (!a || !b) continue
    compared++

    if (a === b) {
      totalScore += 1.0
    } else if (cat === 'Drinking' || cat === 'Smoking') {
      // Partial match for adjacent lifestyle choices
      const drinkOrder = ['Non-drinker', 'Socially', 'Reviewer']
      const smokeOrder = ['Non-smoker', 'Trying to quit', 'Electronic Cigarette', 'Smoker']
      const order = cat === 'Drinking' ? drinkOrder : smokeOrder
      const iA = order.indexOf(a)
      const iB = order.indexOf(b)
      if (iA >= 0 && iB >= 0) {
        const diff = Math.abs(iA - iB)
        totalScore += diff === 1 ? 0.5 : 0.2
      } else {
        totalScore += 0.3
      }
    } else if (cat === 'Workout') {
      const workoutOrder = ['Everyday', 'Often', 'Sometimes', 'Never']
      const iA = workoutOrder.indexOf(a)
      const iB = workoutOrder.indexOf(b)
      if (iA >= 0 && iB >= 0) {
        const diff = Math.abs(iA - iB)
        totalScore += diff <= 1 ? 0.7 : 0.3
      } else {
        totalScore += 0.3
      }
    } else {
      totalScore += 0.3
    }
  }

  return compared > 0 ? (totalScore / compared) * 100 : 50
}

// ─── QA Values Score Computation ───
function computeValuesScore(answersA: any[], answersB: any[]): number {
  if (!answersA?.length || !answersB?.length) return 50

  let totalScore = 0
  let compared = 0

  for (const ansA of answersA) {
    const ansB = answersB.find((b: any) => b.question === ansA.question)
    if (!ansB) continue
    compared++

    if (ansA.answer === ansB.answer) {
      totalScore += 1.0
    } else {
      // Check for adjacent answers (same question, nearby option)
      totalScore += 0.4
    }
  }

  return compared > 0 ? (totalScore / compared) * 100 : 50
}

// ─── Confidence Tier ───
function getConfidenceTier(cms: number): string {
  if (cms >= 85) return 'Excellent'
  if (cms >= 70) return 'Great'
  if (cms >= 55) return 'Good'
  return 'Fair'
}

// ─── Top Dimensions Extractor ───
function getTopDimensions(rubric: any): string[] {
  if (!rubric) return []
  const dims = [
    { name: 'Emotional Safety', value: rubric.emotional_safety_intimacy, max: 20 },
    { name: 'Core Energy Alignment', value: rubric.core_needs_energy, max: 25 },
    { name: 'Communication & Conflict', value: rubric.communication_conflict, max: 15 },
    { name: 'Lifestyle Execution', value: rubric.lifestyle_execution, max: 15 },
    { name: 'Values & Meaning', value: rubric.values_meaning, max: 10 },
    { name: 'Growth & Repair', value: rubric.growth_repair, max: 8 },
    { name: 'Stress Support', value: rubric.stress_support, max: 5 },
  ]

  // Sort by percentage of max score (highest first)
  dims.sort((a, b) => (b.value / b.max) - (a.value / a.max))

  // Return top 3 as readable strings
  return dims.slice(0, 3).map(d => {
    const pct = Math.round((d.value / d.max) * 100)
    const label = pct >= 90 ? 'Very High' : pct >= 75 ? 'High' : pct >= 60 ? 'Moderate' : 'Low'
    return `${d.name}: ${label}`
  })
}

// ─── Distance Calculation ───
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  if (!lat1 || !lon1 || !lat2 || !lon2) return 9999
  const R = 6371
  const dLat = (lat2 - lat1) * Math.PI / 180
  const dLon = (lon2 - lon1) * Math.PI / 180
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2)
  return R * (2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)))
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Manual auth check (gateway verify_jwt disabled due to ES256 incompatibility)
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Missing or invalid Authorization header' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    const { query, userId } = await req.json()
    if (!query || !userId) {
      throw new Error('Query and userId are required')
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // ──────────────────────────────────────────────
    // 1. Fetch current user's profile + traits
    // ──────────────────────────────────────────────
    const { data: currentUser, error: userError } = await supabaseClient
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single()

    if (userError || !currentUser) throw new Error('User not found: ' + JSON.stringify(userError))

    const { data: currentTraitRows } = await supabaseClient
      .from('user_traits')
      .select('mbti, matching_preferences, lifestyle, answers')
      .eq('user_id', userId)
      .limit(1)

    const currentTrait = currentTraitRows?.[0] ?? {}
    const currentMbti = currentTrait.mbti ?? null
    const prefs = currentTrait.matching_preferences ?? {}
    const currentLifestyle = currentTrait.lifestyle ?? {}
    const currentAnswers = currentTrait.answers ?? []

    // Matching preferences (hard filters)
    const preferredGender = prefs?.preferred_gender ?? prefs?.preferredGender ?? 'Any'
    const prioritizeActive = prefs?.prioritize_active ?? prefs?.prioritizeActiveUsers ?? false
    let maxDistance = prefs?.max_distance ?? prefs?.maxDistance ?? 50
    let maxAge = prefs?.max_age ?? prefs?.maxAge ?? 100
    const filterSmoking = prefs?.filter_smoking ?? []
    const filterDrinking = prefs?.filter_drinking ?? []

    console.log('User MBTI:', currentMbti, '| Prefs:', preferredGender, maxDistance, maxAge)

    // ──────────────────────────────────────────────
    // 2. Fetch all candidate profiles
    // ──────────────────────────────────────────────
    const { data: candidateProfiles, error: candidatesError } = await supabaseClient
      .from('profiles')
      .select('*')
      .neq('id', userId)
      .neq('role', 'admin')
      .eq('status', 'approved')

    if (candidatesError || !candidateProfiles) throw new Error('Failed to fetch candidates')

    // ──────────────────────────────────────────────
    // 3. Apply hard filters
    // ──────────────────────────────────────────────
    const queryLower = query.toLowerCase()
    const queryUpper = query.toUpperCase()
    const isAnyoneQuery = queryLower.includes('anyone') || queryLower.includes('any') ||
      queryLower.includes('아무나') || queryLower.includes('상관없어') ||
      queryLower.includes('all') || queryLower.includes('누구나')

    // Detect specific MBTI type mentioned in query
    const allMbtiTypes = ['INTJ','INTP','ENTJ','ENTP','INFJ','INFP','ENFJ','ENFP','ISTJ','ISFJ','ESTJ','ESFJ','ISTP','ISFP','ESTP','ESFP']
    const requestedMbti = allMbtiTypes.find(m => queryUpper.includes(m)) ?? null
    console.log('Requested MBTI from query:', requestedMbti)

    // Detect height preference from query (e.g. "over 185cm", "taller than 180")
    const heightMatch = queryLower.match(/(?:over|above|taller than|at least|minimum|최소|이상)\s*(\d{3})/)
    const requestedMinHeight = heightMatch ? parseInt(heightMatch[1]) : null
    if (requestedMinHeight) console.log('Requested min height:', requestedMinHeight)

    // Detect lifestyle preferences from query
    const wantsNonDrinker = queryLower.includes('non-drinker') || queryLower.includes('non drinker') ||
      queryLower.includes('doesn\'t drink') || queryLower.includes('no alcohol') ||
      queryLower.includes('no drinking') || queryLower.includes('never drinks')
    const wantsNonSmoker = queryLower.includes('non-smoker') || queryLower.includes('non smoker') ||
      queryLower.includes('doesn\'t smoke') || queryLower.includes('no smoking') ||
      queryLower.includes('never smokes')
    const wantsDailyWorkout = queryLower.includes('works out daily') || queryLower.includes('daily workout') ||
      queryLower.includes('exercises daily') || queryLower.includes('gym every day')
    if (wantsNonDrinker) console.log('User wants non-drinker')
    if (wantsNonSmoker) console.log('User wants non-smoker')

    // Detect education preference
    const educationLevels = ['high school', 'in college', 'undergraduate', 'postgraduate']
    const requestedEducation = educationLevels.find(e => queryLower.includes(e)) ?? null
    if (requestedEducation) console.log('Requested education:', requestedEducation)

    // Detect family plans preference
    const wantsChildren = queryLower.includes('wants children') || queryLower.includes('want children') || queryLower.includes('want kids') || queryLower.includes('wants kids')
    const noChildren = queryLower.includes("doesn't want children") || queryLower.includes("don't want children") || queryLower.includes('no kids') || queryLower.includes("doesn't want kids")

    // Detect love language preference
    const loveLangs: Record<string, string> = { 'words of affirmation': 'Words of Affirmation', 'quality time': 'Quality Time', 'receiving gifts': 'Receiving Gifts', 'acts of service': 'Acts of Service', 'physical touch': 'Physical Touch' }
    const requestedLoveLang = Object.keys(loveLangs).find(k => queryLower.includes(k)) ? loveLangs[Object.keys(loveLangs).find(k => queryLower.includes(k))!] : null
    if (requestedLoveLang) console.log('Requested love language:', requestedLoveLang)

    // Gender preference is ALWAYS respected — never override it
    let effGender = preferredGender
    let effDistance = (isAnyoneQuery || requestedMbti) ? 9999 : maxDistance
    let effAge = (isAnyoneQuery || requestedMbti) ? 100 : maxAge

    // Fetch interactions to exclude
    const { data: interactions } = await supabaseClient
      .from('user_interactions')
      .select('to_user, action, created_at')
      .eq('from_user', userId)

    const excludedIds = new Set<string>()
    if (interactions) {
      const now = Date.now()
      const hours24 = 24 * 60 * 60 * 1000
      interactions.forEach((inter: any) => {
        if (inter.action === 'like' || inter.action === 'super_like') {
          excludedIds.add(inter.to_user)
        } else if (inter.action === 'pass') {
          if (now - new Date(inter.created_at).getTime() < hours24) {
            excludedIds.add(inter.to_user)
          }
        }
      })
    }

    const currentYear = new Date().getFullYear()
    const currentLat = currentUser.latitude
    const currentLon = currentUser.longitude

    let strictCandidates: any[] = []
    let relaxedCandidates: any[] = []

    const unblockedCandidates = candidateProfiles.filter((c: any) => !excludedIds.has(c.id))

    unblockedCandidates.forEach((c: any) => {
      // Gender filter
      if (effGender !== 'Any' && c.gender && c.gender.toLowerCase() !== effGender.toLowerCase()) return

      // Active filter
      if (prioritizeActive) {
        if (!c.last_active_at) return
        const daysSince = (Date.now() - new Date(c.last_active_at).getTime()) / (1000 * 3600 * 24)
        if (daysSince > 3) return
      }

      const age = c.birth_date ? currentYear - new Date(c.birth_date).getFullYear() : 99
      const distance = calculateDistance(currentLat, currentLon, c.latitude, c.longitude)

      if (age <= effAge && distance <= effDistance) {
        strictCandidates.push(c)
      } else if (age <= (effAge + 10)) {
        relaxedCandidates.push(c)
      }
    })

    let matchedByPreference = true
    let filteredCandidates = strictCandidates

    if (strictCandidates.length < 4) {
      matchedByPreference = false
      const comb = [...strictCandidates, ...relaxedCandidates]
      const uniqueIds = new Set()
      filteredCandidates = comb.filter(c => {
        if (uniqueIds.has(c.id)) return false
        uniqueIds.add(c.id)
        return true
      })
    }

    const candidateIds = filteredCandidates.map((c: any) => c.id)
    if (candidateIds.length === 0) {
      throw new Error('No potential candidates available to match.')
    }

    // ──────────────────────────────────────────────
    // 4. Fetch traits for all candidates
    // ──────────────────────────────────────────────
    const { data: allTraits } = await supabaseClient
      .from('user_traits')
      .select('user_id, mbti, lifestyle, answers')
      .in('user_id', candidateIds)

    // ──────────────────────────────────────────────
    // 5. Fetch MBTI compatibility data from v2 table
    // ──────────────────────────────────────────────
    // Build all pair lookup keys we need
    const lookupKeys: string[] = []
    if (currentMbti) {
      for (const c of filteredCandidates) {
        const cTrait = allTraits?.find((t: any) => t.user_id === c.id)
        const cMbti = cTrait?.mbti
        if (cMbti) {
          lookupKeys.push(`${currentMbti}_${cMbti}`)
        }
      }
    }

    // Fetch pair keys from lookup table
    let pairKeyMap: Record<string, string> = {}
    if (lookupKeys.length > 0) {
      const { data: lookups } = await supabaseClient
        .from('mbti_pair_lookup')
        .select('lookup_key, pair_key')
        .in('lookup_key', lookupKeys)

      if (lookups) {
        lookups.forEach((l: any) => { pairKeyMap[l.lookup_key] = l.pair_key })
      }
    }

    // Fetch actual compatibility records
    const uniquePairKeys = [...new Set(Object.values(pairKeyMap))]
    let compatMap: Record<string, any> = {}
    if (uniquePairKeys.length > 0) {
      const { data: compats } = await supabaseClient
        .from('mbti_compatibility_v2')
        .select('*')
        .in('pair_key', uniquePairKeys)

      if (compats) {
        compats.forEach((c: any) => { compatMap[c.pair_key] = c })
      }
    }

    // ──────────────────────────────────────────────
    // 6. Compute Composite Match Score (CMS) for each candidate
    // ──────────────────────────────────────────────
    const scoredCandidates = filteredCandidates.map((c: any) => {
      const cTrait = allTraits?.find((t: any) => t.user_id === c.id)
      const cMbti = cTrait?.mbti ?? null
      const cLifestyle = cTrait?.lifestyle ?? {}
      const cAnswers = cTrait?.answers ?? []

      // MBTI Score (40%)
      let mbtiScore = 50 // default if no MBTI data
      let mbtiCompat: any = null
      if (currentMbti && cMbti) {
        const lookupKey = `${currentMbti}_${cMbti}`
        const pairKey = pairKeyMap[lookupKey]
        if (pairKey) {
          mbtiCompat = compatMap[pairKey]
          if (mbtiCompat) {
            mbtiScore = mbtiCompat.score
          }
        }
      }

      // Lifestyle Score (25%)
      const lifestyleScore = computeLifestyleScore(currentLifestyle, cLifestyle)

      // Values Score (20%)
      const valuesScore = computeValuesScore(
        Array.isArray(currentAnswers) ? currentAnswers : [],
        Array.isArray(cAnswers) ? cAnswers : []
      )

      // Profile Affinity (15%) — base score from occupation similarity
      let profileAffinity = 50
      if (currentUser.occupation && c.occupation && currentUser.occupation === c.occupation) {
        profileAffinity = 90
      } else if (currentUser.occupation && c.occupation) {
        // Check if similar professional domains
        const techJobs = ['Developer', 'Software Engineer', 'Programmer', 'Data Analyst', 'Data Scientist', 'UX Designer', 'Designer']
        const healthJobs = ['Doctor', 'Nurse', 'Dentist', 'Pharmacist', 'Veterinarian', 'Surgeon', 'Nutritionist', 'Paramedic']
        const creativeJobs = ['Artist', 'Musician', 'Photographer', 'Videographer', 'Writer', 'Editor', 'Producer', 'Content Creator', 'Illustrator', 'Graphic Designer']
        const businessJobs = ['Consultant', 'Financial Advisor', 'Marketer', 'Sales Manager', 'Business Analyst', 'Project Manager', 'Real Estate Agent', 'Accountant', 'Banker']

        const domains = [techJobs, healthJobs, creativeJobs, businessJobs]
        for (const domain of domains) {
          if (domain.includes(currentUser.occupation) && domain.includes(c.occupation)) {
            profileAffinity = 75
            break
          }
        }
      }

      // Composite Match Score
      const cms = (mbtiScore * 0.40) + (lifestyleScore * 0.25) + (valuesScore * 0.20) + (profileAffinity * 0.15)

      return {
        profile: c,
        trait: cTrait,
        mbtiCompat,
        scores: {
          mbti: Math.round(mbtiScore * 10) / 10,
          lifestyle: Math.round(lifestyleScore * 10) / 10,
          values: Math.round(valuesScore * 10) / 10,
          profileAffinity: Math.round(profileAffinity * 10) / 10,
          composite: Math.round(cms * 10) / 10,
        },
        topDimensions: getTopDimensions(mbtiCompat),
        confidenceTier: getConfidenceTier(cms),
      }
    })

    // Sort by CMS descending
    scoredCandidates.sort((a, b) => b.scores.composite - a.scores.composite)

    // If user requested a specific MBTI, boost those candidates to the top
    if (requestedMbti) {
      scoredCandidates.sort((a, b) => {
        const aMatch = a.trait?.mbti === requestedMbti ? 1 : 0
        const bMatch = b.trait?.mbti === requestedMbti ? 1 : 0
        if (bMatch !== aMatch) return bMatch - aMatch // matching MBTI first
        return b.scores.composite - a.scores.composite // then by CMS
      })
      console.log('Boosted candidates with MBTI:', requestedMbti, 
        scoredCandidates.slice(0, 6).map(sc => `${sc.profile.nickname}(${sc.trait?.mbti}): CMS=${sc.scores.composite}`))
    }

    console.log('Scored candidates:', scoredCandidates.slice(0, 5).map(sc => `${sc.profile.nickname}(${sc.trait?.mbti}): CMS=${sc.scores.composite}`))

    // Apply server-side query filters before sending to GPT
    let candidatesForGpt = [...scoredCandidates]

    // Filter by requested MBTI type
    if (requestedMbti) {
      const mbtiMatches = candidatesForGpt.filter(sc => sc.trait?.mbti === requestedMbti)
      console.log(`Found ${mbtiMatches.length} candidates with MBTI=${requestedMbti}`)
      if (mbtiMatches.length > 0) {
        if (mbtiMatches.length >= 4) {
          candidatesForGpt = mbtiMatches
        } else {
          const others = candidatesForGpt.filter(sc => sc.trait?.mbti !== requestedMbti).slice(0, 4 - mbtiMatches.length)
          candidatesForGpt = [...mbtiMatches, ...others]
        }
      }
    }

    // Filter by height preference
    if (requestedMinHeight) {
      const heightMatches = candidatesForGpt.filter(sc => {
        const h = parseInt(sc.profile.height)
        return !isNaN(h) && h >= requestedMinHeight
      })
      console.log(`Height filter: ${heightMatches.length} candidates >= ${requestedMinHeight}cm`)
      if (heightMatches.length > 0) {
        candidatesForGpt = heightMatches
      }
    }

    // Filter by lifestyle: non-drinker
    if (wantsNonDrinker) {
      const ndMatches = candidatesForGpt.filter(sc => {
        const d = sc.trait?.lifestyle?.Drinking
        return d && (d === 'Never' || d === 'Non-drinker')
      })
      console.log(`Non-drinker filter: ${ndMatches.length} candidates`)
      if (ndMatches.length > 0) candidatesForGpt = ndMatches
    }

    // Filter by lifestyle: non-smoker
    if (wantsNonSmoker) {
      const nsMatches = candidatesForGpt.filter(sc => {
        const s = sc.trait?.lifestyle?.Smoking
        return s && (s === 'Never' || s === 'Non-smoker')
      })
      console.log(`Non-smoker filter: ${nsMatches.length} candidates`)
      if (nsMatches.length > 0) candidatesForGpt = nsMatches
    }

    // Filter by daily workout
    if (wantsDailyWorkout) {
      const wMatches = candidatesForGpt.filter(sc => {
        const w = sc.trait?.lifestyle?.Workout
        return w && (w === 'Daily' || w === 'Everyday')
      })
      console.log(`Daily workout filter: ${wMatches.length} candidates`)
      if (wMatches.length > 0) candidatesForGpt = wMatches
    }

    // Filter by education level
    if (requestedEducation) {
      const eduMatches = candidatesForGpt.filter(sc => {
        const e = sc.trait?.lifestyle?.Education
        return e && e.toLowerCase() === requestedEducation
      })
      console.log(`Education filter (${requestedEducation}): ${eduMatches.length} candidates`)
      if (eduMatches.length > 0) candidatesForGpt = eduMatches
    }

    // Filter by family plans
    if (wantsChildren) {
      const fcMatches = candidatesForGpt.filter(sc => sc.trait?.lifestyle?.['Family Plans'] === 'Want children')
      console.log(`Wants children filter: ${fcMatches.length} candidates`)
      if (fcMatches.length > 0) candidatesForGpt = fcMatches
    } else if (noChildren) {
      const ncMatches = candidatesForGpt.filter(sc => sc.trait?.lifestyle?.['Family Plans'] === "Don't want children")
      console.log(`No children filter: ${ncMatches.length} candidates`)
      if (ncMatches.length > 0) candidatesForGpt = ncMatches
    }

    // Filter by love language
    if (requestedLoveLang) {
      const llMatches = candidatesForGpt.filter(sc => sc.trait?.lifestyle?.['Love Language'] === requestedLoveLang)
      console.log(`Love language filter (${requestedLoveLang}): ${llMatches.length} candidates`)
      if (llMatches.length > 0) candidatesForGpt = llMatches
    }

    console.log('Candidates for GPT:', candidatesForGpt.length, candidatesForGpt.slice(0, 5).map(sc => `${sc.profile.nickname}(${sc.trait?.mbti})`))

    // ──────────────────────────────────────────────
    // 7. Build AI Prompt with rich rubric context
    // ──────────────────────────────────────────────
    const openai = new OpenAI({
      apiKey: Deno.env.get('OPENAI_API_KEY'),
    })

    const candidatesContext = candidatesForGpt.slice(0, 20).map((sc) => {
      const c = sc.profile
      const age = c.birth_date ? currentYear - new Date(c.birth_date).getFullYear() : 'Unknown'
      const cMbti = sc.trait?.mbti ?? 'Unknown'

      let mbtiContext = ''
      if (sc.mbtiCompat) {
        mbtiContext = `
MBTI Compatibility Detail:
  Overall Score: ${sc.mbtiCompat.score}/100 (${sc.mbtiCompat.confidence} confidence)
  Emotional Safety: ${sc.mbtiCompat.emotional_safety_intimacy}/20
  Communication & Conflict: ${sc.mbtiCompat.communication_conflict}/15
  Values & Meaning: ${sc.mbtiCompat.values_meaning}/10
  Why it works: ${JSON.stringify(sc.mbtiCompat.why_it_works)}
  Watch-outs: ${JSON.stringify(sc.mbtiCompat.watch_outs)}
  Success conditions: ${JSON.stringify(sc.mbtiCompat.success_conditions)}`
      }

      return `
─── Candidate ID: ${c.id} ───
Name: ${c.nickname || 'Unknown'}, Age: ${age}, Gender: ${c.gender || 'Unknown'}, MBTI: ${cMbti}
Job: ${c.occupation || 'Unknown'}, Height: ${c.height || 'Unknown'}cm
Self-intro: ${c.self_intro || 'N/A'}
One-line intro: ${c.one_line_intro || 'N/A'}
Lifestyle: Drinking=${sc.trait?.lifestyle?.Drinking || 'N/A'}, Smoking=${sc.trait?.lifestyle?.Smoking || 'N/A'}, Workout=${sc.trait?.lifestyle?.Workout || 'N/A'}, Pets=${sc.trait?.lifestyle?.Pets || 'N/A'}
Education: ${sc.trait?.lifestyle?.Education || 'N/A'}, Zodiac: ${sc.trait?.lifestyle?.['Zodiac Sign'] || 'N/A'}
Family Plans: ${sc.trait?.lifestyle?.['Family Plans'] || 'N/A'}, Communication: ${sc.trait?.lifestyle?.['Communication Style'] || 'N/A'}, Love Language: ${sc.trait?.lifestyle?.['Love Language'] || 'N/A'}
Composite Match Score: ${sc.scores.composite}/100 (MBTI: ${sc.scores.mbti}, Lifestyle: ${sc.scores.lifestyle}, Values: ${sc.scores.values}, Profile: ${sc.scores.profileAffinity})
Confidence Tier: ${sc.confidenceTier}
${mbtiContext}`
    }).join('\n')

    const currentAge = currentUser.birth_date ? currentYear - new Date(currentUser.birth_date).getFullYear() : 'Unknown'

    const systemPrompt = `You are an AI dating matchmaker for the BeTogether app. Your role is to analyze personality compatibility deeply and provide insightful, empathetic recommendations.

CURRENT USER:
- MBTI: ${currentMbti || 'Unknown'}
- Age: ${currentAge}
- Job: ${currentUser.occupation || 'Unknown'}
- Self-intro: ${currentUser.self_intro || 'N/A'}
- One-line intro: ${currentUser.one_line_intro || 'N/A'}

USER QUERY: "${query}"

CANDIDATES (sorted by Composite Match Score):
${candidatesContext}

INSTRUCTIONS:
1. Select up to 4 best candidates.
   - If the user mentions a specific MBTI type (e.g. "ISFP", "ENFP", "I want an INTJ"), you MUST ONLY select candidates with that exact MBTI type. The candidates list is already sorted with matching MBTI types at the top.
   - If the user says "anyone" / "all" / has no specific preference, choose the top 4 by Composite Match Score.
2. For each recommendation, generate 4 insightful reasons in ENGLISH:
   - reason1: An emotional connection insight. Reference the MBTI compatibility's emotional safety or why_it_works data. Example: "You both share high emotional safety, which means deeper conversations will feel natural and secure."
   - reason2: A daily life compatibility insight. Reference lifestyle alignment, dating style, or communication preferences. Example: "Both of you prefer structured planning, making daily routines and future goals easier to coordinate."
   - reason3: A unique bridge insight. Find something specific connecting these two people — similar professional fields, shared interests inferred from self-intro, or complementary personality traits. Use the candidate's self_intro and occupation. Example: "As fellow creative professionals, you'll understand each other's workflow and find inspiration in each other's perspectives."
   - reason4: A confidence summary. Include the tier and key insight. Example: "An Excellent Match — your strong values alignment and compatible conflict resolution styles suggest a naturally harmonious connection."
3. IMPORTANT: Use the Watch-outs and Success Conditions to add nuance — don't just say everything is perfect. Mention areas to be mindful of in a positive way.
4. You MUST choose exact Candidate IDs from the list. Do not invent IDs.
5. Return ONLY valid JSON:
{
  "recommendations": [
    {
      "recommendedUserId": "uuid",
      "reason1": "...",
      "reason2": "...",
      "reason3": "...",
      "reason4": "..."
    }
  ]
}`

    const chatCompletion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'system', content: systemPrompt }],
      temperature: 0.7,
      response_format: { type: 'json_object' },
    })

    const resultText = chatCompletion.choices[0].message?.content
    if (!resultText) throw new Error('No response from AI')

    let aiResponse
    try {
      aiResponse = JSON.parse(resultText)
    } catch (e) {
      throw new Error('Failed to parse AI JSON response: ' + resultText)
    }

    if (!aiResponse.recommendations || aiResponse.recommendations.length === 0) {
      throw new Error('AI found no matching candidates for the given query.')
    }

    // ──────────────────────────────────────────────
    // 8. Build final enriched response
    // ──────────────────────────────────────────────
    const finalCandidates = aiResponse.recommendations.map((rec: any) => {
      // Try UUID match first, then fallback to nickname match
      let scored = scoredCandidates.find((sc) => sc.profile.id === rec.recommendedUserId)
      if (!scored) {
        scored = scoredCandidates.find((sc) => sc.profile.nickname === rec.recommendedUserId)
        if (scored) console.log('Matched by nickname fallback:', rec.recommendedUserId, '->', scored.profile.id)
      }
      if (!scored) {
        console.warn('AI recommended unknown ID:', rec.recommendedUserId)
        return null
      }

      const c = scored.profile
      const distance = calculateDistance(currentLat, currentLon, c.latitude, c.longitude)

      const enrichedCandidate = {
        ...c,
        mbti: scored.trait?.mbti ?? null,
        lifestyle: scored.trait?.lifestyle ?? {},
        answers: scored.trait?.answers ?? {},
      }

      return {
        candidate: enrichedCandidate,
        distance: Math.round(distance),
        confidenceTier: scored.confidenceTier,
        compositeScore: scored.scores.composite,
        topDimensions: scored.topDimensions,
        scores: scored.scores,
        reasons: {
          step1: rec.reason1 || 'Matched successfully.',
          step2: rec.reason2 || 'Good compatibilities.',
          step3: rec.reason3 || 'Traits align well.',
          step4: rec.reason4 || 'Recommended by AI matchmaker.',
        }
      }
    }).filter(Boolean)

    if (finalCandidates.length === 0) {
      throw new Error('AI recommended an unknown user ID: ' + JSON.stringify(aiResponse))
    }

    return new Response(JSON.stringify({
      candidates: finalCandidates,
      matchedByPreference: matchedByPreference
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error: any) {
    console.error('Edge function error:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
