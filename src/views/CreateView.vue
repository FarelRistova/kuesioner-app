<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../supabase'

const router = useRouter()
const route = useRoute()
const MAX_QUESTIONS = 20
const editingId = computed(() => route.name === 'edit' ? route.params.id : null)

const title = ref('')
const description = ref('')
const questions = reactive([
  { text: 'Produk apa yang paling kamu suka?', type: 'choice', optionsText: '' },
  { text: 'Berapa rating kamu untuk produk kami?', type: 'rating', optionsText: '' },
])

const saving = ref(false)
const loading = ref(Boolean(editingId.value))
const error = ref('')
const originalQuestionIds = ref([])

const typeLabels = {
  choice: 'Pilihan (pilih satu)',
  rating: 'Rating 1–5',
  text: 'Jawaban teks bebas',
}

function addQuestion() {
  if (questions.length >= MAX_QUESTIONS) return
  questions.push({ text: '', type: 'choice', optionsText: '' })
}

function removeQuestion(i) {
  questions.splice(i, 1)
}

function parseOptions(text) {
  const seen = new Set()
  return text
    .split('\n')
    .map((o) => o.trim())
    .filter((o) => {
      if (!o || seen.has(o.toLowerCase())) return false
      seen.add(o.toLowerCase())
      return true
    })
}

function validate() {
  if (!title.value.trim()) return 'Judul kuesioner wajib diisi.'
  if (!questions.length) return 'Tambahkan minimal satu pertanyaan.'
  for (const [i, q] of questions.entries()) {
    if (!q.text.trim()) return `Pertanyaan ${i + 1} belum diisi.`
    if (q.type === 'choice' && parseOptions(q.optionsText).length < 2) {
      return `Pertanyaan ${i + 1} butuh minimal 2 pilihan (satu pilihan per baris).`
    }
  }
  return ''
}

onMounted(async () => {
  if (!editingId.value) return
  const [surveyResult, questionsResult] = await Promise.all([
    supabase.from('surveys').select('title,description').eq('id', editingId.value).maybeSingle(),
    supabase.from('questions').select('*').eq('survey_id', editingId.value).order('position'),
  ])
  if (surveyResult.error) error.value = 'Gagal memuat kuesioner: ' + surveyResult.error.message
  else if (!surveyResult.data) error.value = 'Kuesioner tidak ditemukan.'
  else {
    title.value = surveyResult.data.title
    description.value = surveyResult.data.description ?? ''
  }
  if (questionsResult.error) error.value = 'Gagal memuat pertanyaan: ' + questionsResult.error.message
  else if (questionsResult.data?.length) {
    originalQuestionIds.value = questionsResult.data.map((q) => q.id)
    questions.splice(0, questions.length, ...questionsResult.data.map((q) => ({
      id: q.id,
      text: q.text,
      type: q.type,
      optionsText: Array.isArray(q.options) ? q.options.join('\n') : '',
    })))
  }
  loading.value = false
})

async function submit() {
  error.value = validate()
  if (error.value) return

  saving.value = true
  const surveyId = editingId.value ?? crypto.randomUUID()

  if (editingId.value) {
    const { error: surveyError } = await supabase.from('surveys').update({
      title: title.value.trim(),
      description: description.value.trim() || null,
    }).eq('id', surveyId)
    if (surveyError) {
      error.value = 'Gagal memperbarui kuesioner: ' + surveyError.message
      saving.value = false
      return
    }

    const currentIds = questions.filter((q) => q.id).map((q) => q.id)
    const removed = originalQuestionIds.value.filter((id) => !currentIds.includes(id))
    if (removed.length) {
      const { error: deleteError } = await supabase.from('questions').delete()
        .eq('survey_id', surveyId).in('id', removed)
      if (deleteError) {
        error.value = 'Gagal menghapus pertanyaan lama: ' + deleteError.message
        saving.value = false
        return
      }
    }

    for (const [i, q] of questions.entries()) {
      const payload = {
        survey_id: surveyId,
        position: i,
        text: q.text.trim(),
        type: q.type,
        options: q.type === 'choice' ? parseOptions(q.optionsText) : [],
        required: q.type !== 'text',
      }
      const result = q.id
        ? await supabase.from('questions').update(payload).eq('id', q.id)
        : await supabase.from('questions').insert(payload)
      if (result.error) {
        error.value = 'Gagal memperbarui pertanyaan: ' + result.error.message
        saving.value = false
        return
      }
    }
    router.push({ name: 'result', params: { id: surveyId } })
    return
  }

  const { error: e1 } = await supabase.from('surveys').insert({
    id: surveyId,
    title: title.value.trim(),
    description: description.value.trim() || null,
  })
  if (e1) {
    error.value = 'Gagal menyimpan kuesioner: ' + e1.message
    saving.value = false
    return
  }

  const rows = questions.map((q, i) => ({
    survey_id: surveyId,
    position: i,
    text: q.text.trim(),
    type: q.type,
    options: q.type === 'choice' ? parseOptions(q.optionsText) : [],
    required: q.type !== 'text',
  }))
  const { error: e2 } = await supabase.from('questions').insert(rows)
  if (e2) {
    error.value = 'Gagal menyimpan pertanyaan: ' + e2.message
    saving.value = false
    return
  }

  router.push({ name: 'result', params: { id: surveyId }, query: { baru: '1' } })
}
</script>

<template>
  <p v-if="loading" class="muted">Memuat kuesioner…</p>
  <template v-else>
  <h1>{{ editingId ? 'Edit Kuesioner' : 'Buat Kuesioner' }}</h1>
  <p class="muted">{{ editingId ? 'Perbarui judul atau pertanyaan kuesioner Anda.' : 'Isi judul dan pertanyaan. Setelah disimpan, Anda akan mendapat link untuk dibagikan.' }}</p>

  <form @submit.prevent="submit">
    <div class="card">
      <label class="field">
        <span class="label">Judul kuesioner</span>
        <input v-model="title" class="input" maxlength="150" placeholder="Contoh: Survei Kepuasan Pelanggan" />
      </label>
      <label class="field" style="margin-bottom: 0">
        <span class="label">Deskripsi (opsional)</span>
        <textarea v-model="description" class="textarea" maxlength="500" placeholder="Jelaskan tujuan kuesioner ini singkat saja" />
      </label>
    </div>

    <div v-for="(q, i) in questions" :key="i" class="card">
      <div class="card-head">
        <strong><span class="q-num">{{ i + 1 }}</span>Pertanyaan</strong>
        <button v-if="questions.length > 1" type="button" class="btn btn-ghost btn-danger btn-sm" @click="removeQuestion(i)">
          Hapus
        </button>
      </div>

      <label class="field">
        <span class="label">Teks pertanyaan</span>
        <input v-model="q.text" class="input" maxlength="300" placeholder="Tulis pertanyaan…" />
      </label>

      <label class="field" :style="{ marginBottom: q.type === 'choice' ? '14px' : '0' }">
        <span class="label">Jenis jawaban</span>
        <select v-model="q.type" class="select">
          <option v-for="(label, key) in typeLabels" :key="key" :value="key">{{ label }}</option>
        </select>
      </label>

      <label v-if="q.type === 'choice'" class="field" style="margin-bottom: 0">
        <span class="label">Pilihan jawaban (satu per baris)</span>
        <textarea v-model="q.optionsText" class="textarea" placeholder="Cheesecuit&#10;Sando&#10;Lainnya" />
      </label>
    </div>

    <div class="row" style="margin-bottom: 20px">
      <button type="button" class="btn" :disabled="questions.length >= MAX_QUESTIONS" @click="addQuestion">
        + Tambah pertanyaan
      </button>
      <span class="muted small">{{ questions.length }} / {{ MAX_QUESTIONS }}</span>
    </div>

    <div v-if="error" class="alert alert-error">{{ error }}</div>

    <button class="btn btn-primary" :disabled="saving">
      {{ saving ? 'Menyimpan…' : editingId ? 'Simpan perubahan' : 'Simpan & dapatkan link' }}
    </button>
  </form>
  </template>
</template>
