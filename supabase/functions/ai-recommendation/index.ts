import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"
import OpenAI from "npm:openai@4.28.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { query, userId } = await req.json()

    if (!query || !userId) {
      throw new Error('Query and userId are required')
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Get current user's profile
    const { data: currentUser, error: userError } = await supabaseClient
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single()

    if (userError || !currentUser) throw new Error('User not found: ' + JSON.stringify(userError))

    // 2. Get current user's MBTI and preferences from user_traits
    const { data: currentTraitRows } = await supabaseClient
      .from('user_traits')
      .select('mbti, matching_preferences')
      .eq('user_id', userId)
      .limit(1)

    const currentMbti = currentTraitRows && currentTraitRows.length > 0 ? currentTraitRows[0].mbti : null
    const prefs = currentTraitRows && currentTraitRows.length > 0 ? currentTraitRows[0].matching_preferences : null
    
    // Default preferences if not found
    const preferredGender = prefs?.preferredGender ?? 'Any'
    const prioritizeActive = prefs?.prioritizeActiveUsers ?? false
    let maxDistance = prefs?.maxDistance ?? 50
    let maxAge = prefs?.maxAge ?? 100
    
    console.log('currentMbti:', currentMbti, 'preferredGender:', preferredGender, 'maxDistance:', maxDistance, 'maxAge:', maxAge, 'prioritizeActive:', prioritizeActive)

    // 3. Fetch all other users' profiles (excluding admin role, only approved)
    const { data: candidateProfiles, error: candidatesError } = await supabaseClient
      .from('profiles')
      .select('*')
      .neq('id', userId)
      .neq('role', 'admin')
      .eq('status', 'approved')

    if (candidatesError || !candidateProfiles) throw new Error('Failed to fetch candidates')

    // 3.5 Fetch current user interactions to filter out ones already liked, or passed within 24h
    const { data: interactions } = await supabaseClient
      .from('user_interactions')
      .select('to_user, action, created_at')
      .eq('from_user', userId)

    const excludedIds = new Set<string>()
    if (interactions) {
      const now = new Date().getTime()
      const hours24 = 24 * 60 * 60 * 1000
      interactions.forEach((inter: any) => {
        if (inter.action === 'like' || inter.action === 'super_like') {
          excludedIds.add(inter.to_user)
        } else if (inter.action === 'pass') {
          const passTime = new Date(inter.created_at).getTime()
          if (now - passTime < hours24) {
            excludedIds.add(inter.to_user)
          }
        }
      })
    }

    // Add distance calculation helper
    function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
      if (!lat1 || !lon1 || !lat2 || !lon2) return 9999;
      const R = 6371; // km
      const dLat = (lat2 - lat1) * Math.PI / 180;
      const dLon = (lon2 - lon1) * Math.PI / 180;
      const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
                Math.sin(dLon/2) * Math.sin(dLon/2); 
      return R * (2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)));
    }

    const unblockedCandidates = candidateProfiles.filter((c: any) => !excludedIds.has(c.id))

    // Fallback Logic Arrays
    let strictCandidates: any[] = []
    let relaxedCandidates: any[] = []

    const currentYear = new Date().getFullYear()
    const currentLat = currentUser.latitude
    const currentLon = currentUser.longitude

    unblockedCandidates.forEach((c: any) => {
      // Base Filters: Gender
      let genderMatch = true
      if (preferredGender !== 'Any' && c.gender && c.gender.toLowerCase() !== preferredGender.toLowerCase()) {
        genderMatch = false
      }

      // Base Filters: Active Status
      let activeMatch = true
      if (prioritizeActive && c.last_active_at) {
        const lastActive = new Date(c.last_active_at).getTime()
        const daysSinceActive = (new Date().getTime() - lastActive) / (1000 * 3600 * 24)
        if (daysSinceActive > 3) activeMatch = false // 3 days cutoff
      } else if (prioritizeActive && !c.last_active_at) {
         activeMatch = false
      }

      if (!genderMatch || !activeMatch) return; // Drop completely if gender or active priority fails

      const age = c.birth_date ? currentYear - new Date(c.birth_date).getFullYear() : 99
      const distance = calculateDistance(currentLat, currentLon, c.latitude, c.longitude)

      // Strict check
      const ageMatch = age <= maxAge
      const distMatch = distance <= maxDistance

      if (ageMatch && distMatch) {
         strictCandidates.push(c)
      } else if (age <= (maxAge + 10)) {
         // Relaxed check: Allow +10 years and completely ignore distance
         relaxedCandidates.push(c)
      }
    })

    let matchedByPreference = true
    let filteredCandidates = strictCandidates
    
    if (strictCandidates.length < 4) {
      matchedByPreference = false
      // Combine strict and relaxed, remove duplicates
      const comb = [...strictCandidates, ...relaxedCandidates]
      const uniqueIds = new Set()
      filteredCandidates = comb.filter(c => {
         if (uniqueIds.has(c.id)) return false
         uniqueIds.add(c.id)
         return true
      })
    }

    // 4. Fetch traits for all chosen candidates
    const candidateIds = filteredCandidates.map((c: any) => c.id)
    if (candidateIds.length === 0) {
      throw new Error('No potential candidates available to match (You are the only user).')
    }

    const { data: allTraits } = await supabaseClient
      .from('user_traits')
      .select('user_id, mbti')
      .in('user_id', candidateIds)

    // 5. Fetch ALL MBTI Compatibilities (no filter - we'll match in code)
    const { data: compatibilities, error: compatError } = await supabaseClient
      .from('mbti_compatibility')
      .select('*')

    if (compatError) throw new Error('Failed to fetch compatibilities')

    console.log('compatibilities count:', compatibilities?.length)

    const openai = new OpenAI({
      apiKey: Deno.env.get('OPENAI_API_KEY'),
    })

    // Build context prompt with properly merged data
    const candidatesContext = filteredCandidates.map((c: any) => {
      const trait = allTraits?.find((t: any) => t.user_id === c.id)
      const candidateMbti = trait?.mbti ?? null

      let compat = { score: 50, reason: '알려지지 않은 궁합입니다.' }
      if (currentMbti && candidateMbti && compatibilities) {
        const found = compatibilities.find((cmp: any) =>
          (cmp.mbti1 === currentMbti && cmp.mbti2 === candidateMbti) ||
          (cmp.mbti2 === currentMbti && cmp.mbti1 === candidateMbti)
        )
        if (found) compat = found
      }

      console.log(`Candidate ${c.nickname}: MBTI=${candidateMbti}, compat score=${compat.score}`)

      const age = c.birth_date
        ? new Date().getFullYear() - new Date(c.birth_date).getFullYear()
        : 'Unknown'

      return `Candidate ID: ${c.id}
Name: ${c.nickname || 'Unknown'}
Age: ${age}
MBTI: ${candidateMbti || 'Unknown'}
Job: ${c.occupation || 'Unknown'}
Height: ${c.height || 'Unknown'}
Drinking: ${c.drinking || 'Unknown'}
Smoking: ${c.smoking || 'Unknown'}
MBTI Compatibility Score with Current User (${currentMbti}): ${compat.score} -> ${compat.reason}`
    }).join('\n\n')

    const systemPrompt = `You are an AI dating app matchmaker. The current user is asking: "${query}".
The current user's info: MBTI is ${currentMbti}, Age is ${new Date().getFullYear() - new Date(currentUser.birth_date).getFullYear()}, Job is ${currentUser.occupation}.

Here is a list of potential candidates:
${candidatesContext}

Based ONLY on the user's query and the candidates provided, find up to 4 of the best matching candidates (if the user asks for "anyone" or "all", provide up to 4 diverse matching candidates).
You MUST choose exact Candidate IDs from the list above. Do not invent an ID or use "Unknown". If no one fits, return an empty array.
You must return the response in strict JSON format matching exactly this structure:
{
  "recommendations": [
    {
      "recommendedUserId": "uuid of the chosen candidate",
      "reason1": "Short explanation about their MBTI compatibility score and detail.",
      "reason2": "Short explanation about their Age or other basic match regarding the query.",
      "reason3": "Short explanation about a specific trait (e.g., non-smoker, job) that matches the query.",
      "reason4": "1-2 sentences summarizing the final recommendation."
    }
  ]
}
Do not include any other text besides the JSON object.`

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

    const finalCandidates = aiResponse.recommendations.map((rec: any) => {
      const bestCandidate = candidateProfiles.find((c: any) => c.id === rec.recommendedUserId)
      if (!bestCandidate) {
        console.warn('AI recommended unknown ID: ' + rec.recommendedUserId)
        return null
      }
      return {
        candidate: bestCandidate,
        reasons: {
          step1: rec.reason1 || "Matched successfully.",
          step2: rec.reason2 || "Good compatibilities.",
          step3: rec.reason3 || "Traits align well.",
          step4: rec.reason4 || "Recommended by AI matchmaker.",
        }
      }
    }).filter(Boolean)

    if (finalCandidates.length === 0) {
      throw new Error('AI recommended an unknown user ID: ' + JSON.stringify(aiResponse))
    }

    const finalResponse = {
      candidates: finalCandidates,
      matchedByPreference: matchedByPreference
    }

    return new Response(JSON.stringify(finalResponse), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
