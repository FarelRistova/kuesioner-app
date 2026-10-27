<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '../supabase'
import ChartCanvas from '../components/ChartCanvas.vue'

const route = useRoute()
const surveyId = route.params.id

const survey = ref(null)
const questions = ref([])
const responses = ref([])
const answers = ref([])
const total = ref(0)

const loading = ref(true)
const refreshing = ref(false)
const error = ref('')
const updatedAt = ref(null)
const copied = ref(false)

const isNew = computed(() => route.query.baru === '1')
const fillUrl = computed(() => `${window.location.origin}/isi/${surveyId}`)

// Supabase membatasi 1000 baris per request, jadi diambil bertahap.
async function fetchAllAnswers() {
  const pageSize = 1000
  const all = []
  for (let from = 0; ; from += pageSize) {
    const { data, error: err } = await supabase
      .from('answers')
      .select('response_id,question_id,value')
      .eq('survey_id', surveyId)
      .order('id')
      .range(from, from + pageSize - 1)
    if (err) throw err
    all.push(...data)
    if (data.length < pageSize) break
  }
  return all
}

async function fetchAllResponses() {
  const pageSize = 1000
  const all = []
  for (let from = 0; ; from += pageSize) {
    const { data, error: err } = await supabase
      .from('responses')
      .select('id,created_at')
      .eq('survey_id', surveyId)
      .order('created_at')
      .range(from, from + pageSize - 1)
    if (err) throw err
    all.push(...data)
    if (data.length < pageSize) break
  }
  return all
}

async function load(silent = false) {
  if (!silent) loading.value = true
  else refreshing.value = true
  try {
    const [s, q, r, a] = await Promise.all([
      supabase.from('surveys').select('id,title,description').eq('id', surveyId).maybeSingle(),
      supabase.from('questions').select('*').eq('survey_id', surveyId).order('position'),
      fetchAllResponses(),
      fetchAllAnswers(),
    ])
    if (s.error) throw s.error
    if (q.error) throw q.error
    if (!s.data) {
      error.value = 'Kuesioner tidak ditemukan.'
      return
    }
    survey.value = s.data
    questions.value = q.data
    responses.value = r
    total.value = r.length
    answers.value = a
    updatedAt.value = new Date()
    error.value = ''
  } catch (e) {
    if (!silent) error.value = 'Gagal memuat hasil: ' + e.message
  } finally {
    loading.value = false
    refreshing.value = false
  }
}

const stats = computed(() => {
  const byQuestion = new Map()
  for (const a of answers.value) {
    if (!byQuestion.has(a.question_id)) byQuestion.set(a.question_id, [])
    byQuestion.get(a.question_id).push(a.value)
  }

  return questions.value.map((q) => {
    const vals = byQuestion.get(q.id) ?? []

    if (q.type === 'choice') {
      const labels = q.options
      const values = labels.map((o) => vals.filter((v) => v === o).length)
      const answered = values.reduce((x, y) => x + y, 0)
      return { q, labels, values, answered }
    }

    if (q.type === 'rating') {
      const labels = ['1', '2', '3', '4', '5']
      const values = labels.map((o) => vals.filter((v) => v === o).length)
      const answered = values.reduce((x, y) => x + y, 0)
      const sum = values.reduce((acc, count, i) => acc + count * (i + 1), 0)
      const avg = answered ? sum / answered : 0
      return { q, labels, values, answered, avg }
    }

    return { q, answered: vals.length, texts: vals.slice(-50).reverse() }
  })
})

function pct(value, answered) {
  return answered ? Math.round((value / answered) * 100) : 0
}

function csvCell(value) {
  return `"${String(value ?? '').replace(/"/g, '""')}"`
}

function fileNamePart(value) {
  return String(value ?? 'pertanyaan')
    .trim()
    .replace(/[<>:"/\\|?*\x00-\x1F]/g, '')
    .replace(/\s+/g, '-')
    .slice(0, 80) || 'pertanyaan'
}

function exportSurvey() {
  const answersByResponse = new Map()
  for (const answer of answers.value) {
    if (!answersByResponse.has(answer.response_id)) answersByResponse.set(answer.response_id, new Map())
    answersByResponse.get(answer.response_id).set(answer.question_id, answer.value)
  }
  const rows = [
    ['Kuesioner', survey.value.title],
    ['Total responden', responses.value.length],
    [],
    ['No', 'Waktu mengisi', ...questions.value.map((q, index) => `Pertanyaan ${index + 1}: ${q.text}`)],
    ...responses.value.map((response, index) => [
      index + 1,
      new Date(response.created_at).toLocaleString('id-ID'),
      ...questions.value.map((q) => answersByResponse.get(response.id)?.get(q.id) ?? ''),
    ]),
  ]
  const csv = '\uFEFF' + rows.map((row) => row.map(csvCell).join(';')).join('\r\n')
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `${fileNamePart(survey.value.title)}-semua-jawaban.csv`
  link.click()
  URL.revokeObjectURL(url)
}

async function copyLink() {
  try {
    await navigator.clipboard.writeText(fillUrl.value)
    copied.value = true
    setTimeout(() => (copied.value = false), 2000)
  } catch { /* abaikan */ }
}

let timer
onMounted(() => {
  load()
  timer = setInterval(() => load(true), 20000)
})
onBeforeUnmount(() => clearInterval(timer))
</script>

<template>
  <p v-if="loading" class="muted">Memuat…</p>
  <div v-else-if="error" class="alert alert-error">{{ error }}</div>

  <template v-else>
    <div v-if="isNew" class="alert alert-ok">
      <strong>Kuesioner berhasil dibuat!</strong> Bagikan link ini ke responden:
    </div>

    <div class="card">
      <div class="share">
        <input class="input" :value="fillUrl" readonly @focus="$event.target.select()" />
        <button class="btn btn-primary" @click="copyLink">{{ copied ? 'Tersalin ✓' : 'Salin link' }}</button>
        <RouterLink :to="{ name: 'fill', params: { id: surveyId } }" class="btn">Buka form</RouterLink>
      </div>
    </div>

    <div class="row-between" style="margin-bottom: 14px">
      <div>
        <h1>Hasil: {{ survey.title }}</h1>
        <p v-if="survey.description" class="muted" style="margin: 0">{{ survey.description }}</p>
      </div>
      <div class="row">
        <RouterLink :to="{ name: 'edit', params: { id: surveyId } }" class="btn btn-sm">Edit kuesioner</RouterLink>
        <button class="btn btn-primary btn-sm" type="button" :disabled="!total" @click="exportSurvey">
          Unduh ke Excel
        </button>
        <button class="btn btn-sm" :disabled="refreshing" @click="load(true)">
          {{ refreshing ? 'Memuat…' : '↻ Segarkan' }}
        </button>
      </div>
    </div>

    <div class="stat-row">
      <div class="stat">
        <div class="stat-value">{{ total }}</div>
        <div class="stat-label">Total responden</div>
      </div>
      <div class="stat">
        <div class="stat-value">{{ questions.length }}</div>
        <div class="stat-label">Pertanyaan</div>
      </div>
    </div>

    <p v-if="updatedAt" class="muted small">
      Diperbarui {{ updatedAt.toLocaleTimeString('id-ID') }} · otomatis menyegarkan tiap 20 detik
    </p>

    <div v-if="!total" class="card empty">Belum ada responden. Bagikan link di atas untuk mulai mengumpulkan jawaban.</div>

    <div v-for="(s, i) in stats" :key="s.q.id" class="card">
      <h2><span class="q-num">{{ i + 1 }}</span>{{ s.q.text }}</h2>
      <p class="muted small">{{ s.answered }} jawaban</p>

      <template v-if="s.q.type === 'choice'">
        <ChartCanvas :labels="s.labels" :values="s.values" horizontal :height="Math.max(140, s.labels.length * 52 + 40)" />
        <table class="table">
          <tr v-for="(label, k) in s.labels" :key="label">
            <td>{{ label }}</td>
            <td><strong>{{ s.values[k] }}</strong></td>
            <td class="muted">{{ pct(s.values[k], s.answered) }}%</td>
          </tr>
        </table>
      </template>

      <template v-else-if="s.q.type === 'rating'">
        <p v-if="s.answered" style="font-size: 1.1rem">
          Rata-rata: <strong>{{ s.avg.toFixed(2) }}</strong> / 5
        </p>
        <ChartCanvas :labels="s.labels" :values="s.values" :height="240" />
      </template>

      <template v-else>
        <p v-if="!s.texts.length" class="muted">Belum ada jawaban.</p>
        <ul v-else class="text-answers">
          <li v-for="(t, k) in s.texts" :key="k">{{ t }}</li>
        </ul>
      </template>
    </div>
  </template>
</template>
