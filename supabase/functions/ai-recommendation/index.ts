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

    // 2. Get current user's MBTI from user_traits
    const { data: currentTraitRows } = await supabaseClient
      .from('user_traits')
      .select('mbti')
      .eq('user_id', userId)
      .limit(1)

    const currentMbti = currentTraitRows && currentTraitRows.length > 0 ? currentTraitRows[0].mbti : null
    console.log('currentMbti:', currentMbti)

    // 3. Fetch all other users' profiles
    const { data: candidateProfiles, error: candidatesError } = await supabaseClient
      .from('profiles')
      .select('*')
      .neq('id', userId)

    if (candidatesError || !candidateProfiles) throw new Error('Failed to fetch candidates')

    // 4. Fetch traits for all candidates
    const candidateIds = candidateProfiles.map((c: any) => c.id)
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
    const candidatesContext = candidateProfiles.map((c: any) => {
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

Based ONLY on the user's query and the candidates provided, find the single best matching candidate.
You must return the response in strict JSON format matching exactly this structure:
{
  "recommendedUserId": "uuid of the chosen candidate",
  "reason1": "Short explanation about their MBTI compatibility score and detail.",
  "reason2": "Short explanation about their Age or other basic match regarding the query.",
  "reason3": "Short explanation about a specific trait (e.g., non-smoker, job) that matches the query.",
  "reason4": "1-2 sentences summarizing the final recommendation."
}
Do not include any other text besides the JSON object.`

    const chatCompletion = await openai.chat.completions.create({
      model: 'gpt-4-turbo-preview',
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

    const bestCandidate = candidateProfiles.find((c: any) => c.id === aiResponse.recommendedUserId)

    if (!bestCandidate) {
      throw new Error('AI recommended an unknown user ID: ' + aiResponse.recommendedUserId)
    }

    const finalResponse = {
      candidate: bestCandidate,
      reasons: {
        step1: aiResponse.reason1,
        step2: aiResponse.reason2,
        step3: aiResponse.reason3,
        step4: aiResponse.reason4,
      },
    }

    return new Response(JSON.stringify(finalResponse), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
