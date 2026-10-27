import { computed, ref } from 'vue'

const credentials = {
  username: 'admin',
  password: 'admin123',
}

const loggedIn = ref(sessionStorage.getItem('kuesioner:logged-in') === '1')

export const isLoggedIn = computed(() => loggedIn.value)

export function login(username, password) {
  if (username === credentials.username && password === credentials.password) {
    loggedIn.value = true
    sessionStorage.setItem('kuesioner:logged-in', '1')
    return true
  }
  return false
}

export function logout() {
  loggedIn.value = false
  sessionStorage.removeItem('kuesioner:logged-in')
}