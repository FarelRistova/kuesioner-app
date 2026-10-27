<script setup>
import { isConfigured } from './supabase'
import { isLoggedIn, logout } from './auth'
import { useRouter } from 'vue-router'
import logoImage from './assets/img/logo.png'

const router = useRouter()

function signOut() {
  logout()
  router.push({ name: 'home' })
}
</script>

<template>
  <header class="topbar">
    <div class="container topbar-inner">
      <RouterLink to="/" class="brand" aria-label="Kuesioner">
        <img :src="logoImage" alt="Crave Bitte" />
      </RouterLink>
      <nav>
        <RouterLink to="/tentang" class="nav-link">Tentang</RouterLink>
        <RouterLink to="/" class="nav-link">Kuesioner</RouterLink>
        <RouterLink v-if="isLoggedIn" to="/buat" class="btn btn-primary btn-sm">+ Buat Kuesioner</RouterLink>
        <RouterLink v-else to="/login" class="btn btn-primary btn-sm">Masuk</RouterLink>
        <button v-if="isLoggedIn" class="btn btn-sm" type="button" @click="signOut">Keluar</button>
      </nav>
    </div>
  </header>

  <main class="container page">
    <div v-if="!isConfigured" class="alert alert-warn">
      <strong>Supabase belum dikonfigurasi.</strong>
      Isi <code>VITE_SUPABASE_URL</code> dan <code>VITE_SUPABASE_ANON_KEY</code> di file
      <code>.env</code> (atau Environment Variables di Vercel), lalu jalankan ulang.
    </div>
    <RouterView v-else />
  </main>

  <footer class="footer">
    <div class="container">Copyright &copy; 2026 Crave Bitte. All rights reserved.</div>
  </footer>
</template>
