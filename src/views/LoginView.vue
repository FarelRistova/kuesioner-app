<script setup>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { login } from '../auth'

const router = useRouter()
const route = useRoute()
const username = ref('')
const password = ref('')
const error = ref('')
const submitting = ref(false)

function submit() {
  error.value = ''
  submitting.value = true
  if (!login(username.value.trim(), password.value)) {
    error.value = 'Username atau password salah.'
    submitting.value = false
    return
  }
  router.replace(typeof route.query.redirect === 'string' ? route.query.redirect : '/')
}
</script>

<template>
  <div class="login-page">
    <form class="card login-card" @submit.prevent="submit">
      <h1>Masuk</h1>
      <p class="muted">Masuk untuk membuat, mengedit, dan melihat hasil kuesioner.</p>

      <div v-if="error" class="alert alert-error">{{ error }}</div>

      <label class="field">
        <span class="label">Username</span>
        <input v-model="username" class="input" autocomplete="username" required autofocus />
      </label>
      <label class="field">
        <span class="label">Password</span>
        <input v-model="password" class="input" type="password" autocomplete="current-password" required />
      </label>
      <button class="btn btn-primary" :disabled="submitting">Masuk</button>
    </form>
  </div>
</template>