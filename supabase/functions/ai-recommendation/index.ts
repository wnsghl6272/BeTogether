import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"
import { Configuration, OpenAIApi } from "https://esm.sh/openai@3.2.1"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
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
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // 1. Get current user's MBTI & Profile
    const { data: currentUser, error: userError } = await supabaseClient
      .from('profiles')
      .select('*, user_traits(*)')
      .eq('id', userId)
      .single()

    if (userError || !currentUser) throw new Error('User not found')
    const currentMbti = currentUser.user_traits[0]?.mbti

    // 2. Fetch all other users (for MVP, we fetch all. In production, PostGIS + age filters would apply first)
    const { data: candidates, error: candidatesError } = await supabaseClient
      .from('profiles')
      .select('*, user_traits(*)')
      .neq('id', userId)
      
    if (candidatesError || !candidates) throw new Error('Failed to fetch candidates')

    // 3. Fetch MBTI Compatibility for the current user
    const { data: compatibilities, error: compatError } = await supabaseClient
      .from('mbti_compatibility')
      .select('*')
      .or(`mbti1.eq.${currentMbti},mbti2.eq.${currentMbti}`)

    if (compatError) throw new Error('Failed to fetch compatibilities')

    // Prepare data for OpenAI
    const openAiConfig = new Configuration({
      apiKey: Deno.env.get('OPENAI_API_KEY'),
    })
    const openai = new OpenAIApi(openAiConfig)

    // Build context prompt
    const candidatesContext = candidates.map(c => {
      const trait = c.user_traits[0] || {}
      
      // Find compatibility score
      const compat = compatibilities?.find(cmp => 
        (cmp.mbti1 === currentMbti && cmp.mbti2 === trait.mbti) ||
        (cmp.mbti2 === currentMbti && cmp.mbti1 === trait.mbti)
      ) || { score: 50, reason: "알려지지 않은 궁합입니다." }

      return `Candidate ID: ${c.id}
Name: ${c.nickname}
Age: ${c.birth_date ? new Date().getFullYear() - new Date(c.birth_date).getFullYear() : 'Unknown'}
MBTI: ${trait.mbti || 'Unknown'}
Job: ${c.occupation || 'Unknown'}
Height: ${c.height || 'Unknown'}
Drinking: ${c.drinking || 'Unknown'}
Smoking: ${c.smoking || 'Unknown'}
MBTI Score with Current User (${currentMbti}): ${compat.score} -> ${compat.reason}`
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
Do not include any other text besides the JSON array.`

    const chatCompletion = await openai.createChatCompletion({
      model: "gpt-4-turbo-preview",
      messages: [{ role: "system", content: systemPrompt }],
      temperature: 0.7,
      response_format: { type: "json_object" }
    });

    const resultText = chatCompletion.data.choices[0].message?.content
    if (!resultText) throw new Error('No response from AI')
    
    let aiResponse;
    try {
        aiResponse = JSON.parse(resultText)
    } catch(e) {
        throw new Error('Failed to parse AI JSON response: ' + resultText)
    }

    // Find the chosen candidate details to return to the client
    const bestCandidate = candidates.find(c => c.id === aiResponse.recommendedUserId)

    if(!bestCandidate) {
         throw new Error('AI recommended an unknown user ID: ' + aiResponse.recommendedUserId)
    }

    // Assemble final response
    const finalResponse = {
        candidate: bestCandidate,
        reasons: {
            step1: aiResponse.reason1,
            step2: aiResponse.reason2,
            step3: aiResponse.reason3,
            step4: aiResponse.reason4
        }
    }

    return new Response(
      JSON.stringify(finalResponse),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
