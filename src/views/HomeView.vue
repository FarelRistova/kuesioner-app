<script setup>
import { onMounted, ref } from 'vue'
import { supabase } from '../supabase'
import { isLoggedIn } from '../auth'

const surveys = ref([])
const loading = ref(true)
const error = ref('')

function formatDate(iso) {
  return new Date(iso).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })
}

onMounted(async () => {
  const { data, error: err } = await supabase
    .from('surveys')
    .select('id,title,description,created_at')
    .order('created_at', { ascending: false })
    .limit(50)
  if (err) error.value = 'Gagal memuat daftar kuesioner: ' + err.message
  else surveys.value = data
  loading.value = false
})
</script>

<template>
  <div class="row-between" style="margin-bottom: 18px">
    <div>
      <h1>Kuesioner</h1>
      <p class="muted">Buat kuesioner, bagikan link-nya, dan pantau hasilnya lewat grafik.</p>
    </div>
    <RouterLink to="/buat" class="btn btn-primary">+ Buat Kuesioner</RouterLink>
  </div>

  <div v-if="error" class="alert alert-error">{{ error }}</div>
  <p v-else-if="loading" class="muted">Memuat…</p>

  <div v-else-if="!surveys.length" class="card empty">
    <p>Belum ada kuesioner.</p>
    <RouterLink to="/buat" class="btn btn-primary">Buat kuesioner pertama</RouterLink>
  </div>

  <template v-else>
    <div v-for="s in surveys" :key="s.id" class="card">
      <div class="list-item">
        <div>
          <h2>{{ s.title }}</h2>
          <p v-if="s.description" class="muted" style="margin-bottom: 4px">{{ s.description }}</p>
          <span class="muted small">{{ formatDate(s.created_at) }}</span>
        </div>
        <div class="row">
          <RouterLink :to="{ name: 'fill', params: { id: s.id } }" class="btn btn-primary btn-sm">Isi</RouterLink>
          <RouterLink v-if="isLoggedIn" :to="{ name: 'result', params: { id: s.id } }" class="btn btn-sm">Lihat Hasil</RouterLink>
          <RouterLink v-if="isLoggedIn" :to="{ name: 'edit', params: { id: s.id } }" class="btn btn-sm">Edit</RouterLink>
        </div>
      </div>
    </div>
  </template>
</template>
