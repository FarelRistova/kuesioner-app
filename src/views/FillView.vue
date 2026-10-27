<script setup>
import { onMounted, reactive, ref } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '../supabase'

const route = useRoute()
const surveyId = route.params.id

const survey = ref(null)
const questions = ref([])
const name = ref('')
const answers = reactive({})

const loading = ref(true)
const loadError = ref('')
const submitting = ref(false)
const error = ref('')
const done = ref(false)

const doneKey = `kuesioner:done:${surveyId}`

onMounted(async () => {
  try {
    const [s, q] = await Promise.all([
      supabase.from('surveys').select('id,title,description').eq('id', surveyId).maybeSingle(),
      supabase.from('questions').select('*').eq('survey_id', surveyId).order('position'),
    ])
    if (s.error) throw s.error
    if (q.error) throw q.error
    if (!s.data) {
      loadError.value = 'Kuesioner tidak ditemukan.'
    } else {
      survey.value = s.data
      questions.value = q.data
    }
    try { done.value = localStorage.getItem(doneKey) === '1' } catch { /* abaikan */ }
  } catch (e) {
    loadError.value = 'Gagal memuat kuesioner: ' + e.message
  } finally {
    loading.value = false
  }
})

async function submit() {
  error.value = ''
  if (!name.value.trim()) {
    error.value = 'Nama wajib diisi.'
    return
  }
  for (const [i, q] of questions.value.entries()) {
    if (q.required && !String(answers[q.id] ?? '').trim()) {
      error.value = `Pertanyaan ${i + 1} wajib dijawab.`
      return
    }
  }

  submitting.value = true
  const responseId = crypto.randomUUID()

  const { error: e1 } = await supabase.from('responses').insert({
    id: responseId,
    survey_id: surveyId,
    respondent_name: name.value.trim(),
  })
  if (e1) {
    error.value = 'Gagal mengirim jawaban: ' + e1.message
    submitting.value = false
    return
  }

  const rows = questions.value
    .filter((q) => String(answers[q.id] ?? '').trim())
    .map((q) => ({
      response_id: responseId,
      survey_id: surveyId,
      question_id: q.id,
      value: String(answers[q.id]).trim(),
    }))

  if (rows.length) {
    const { error: e2 } = await supabase.from('answers').insert(rows)
    if (e2) {
      error.value = 'Gagal menyimpan jawaban: ' + e2.message
      submitting.value = false
      return
    }
  }

  try { localStorage.setItem(doneKey, '1') } catch { /* abaikan */ }
  done.value = true
  submitting.value = false
}

</script>

<template>
  <p v-if="loading" class="muted">Memuat…</p>
  <div v-else-if="loadError" class="alert alert-error">{{ loadError }}</div>

  <div v-else-if="done" class="card empty">
    <h1>Terima kasih! 🎉</h1>
    <p>Jawaban Anda sudah tersimpan.</p>
    <div class="row" style="justify-content: center">
      <RouterLink :to="{ name: 'result', params: { id: surveyId } }" class="btn btn-primary">Lihat hasil</RouterLink>
    </div>
  </div>

  <template v-else>
    <h1>{{ survey.title }}</h1>
    <p v-if="survey.description" class="muted">{{ survey.description }}</p>

    <form @submit.prevent="submit" style="margin-top: 18px">
      <div class="card">
        <label class="field" style="margin-bottom: 0">
          <span class="label">Nama Anda</span>
          <input v-model="name" class="input" maxlength="100" placeholder="Tulis nama Anda" autocomplete="name" />
        </label>
      </div>

      <div v-for="(q, i) in questions" :key="q.id" class="card">
        <p><strong><span class="q-num">{{ i + 1 }}</span>{{ q.text }}</strong>
          <span v-if="!q.required" class="muted small"> (opsional)</span></p>

        <div v-if="q.type === 'choice'" class="choice-list">
          <label v-for="opt in q.options" :key="opt" class="choice">
            <input v-model="answers[q.id]" type="radio" :name="q.id" :value="opt" />
            <span>{{ opt }}</span>
          </label>
        </div>

        <template v-else-if="q.type === 'rating'">
          <div class="rating">
            <label v-for="n in 5" :key="n">
              <input v-model="answers[q.id]" type="radio" :name="q.id" :value="String(n)" />
              <span>{{ n }}</span>
            </label>
          </div>
          <div class="rating-legend"><span>Kurang</span><span>Sangat baik</span></div>
        </template>

        <textarea v-else v-model="answers[q.id]" class="textarea" maxlength="1000" placeholder="Tulis jawaban Anda…" />
      </div>

      <div v-if="error" class="alert alert-error">{{ error }}</div>

      <button class="btn btn-primary" :disabled="submitting">
        {{ submitting ? 'Mengirim…' : 'Kirim jawaban' }}
      </button>
    </form>
  </template>
</template>
