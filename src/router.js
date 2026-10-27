import { createRouter, createWebHistory } from 'vue-router'
import HomeView from './views/HomeView.vue'
import CreateView from './views/CreateView.vue'
import FillView from './views/FillView.vue'
import ResultView from './views/ResultView.vue'
import AboutView from './views/AboutView.vue'
import LoginView from './views/LoginView.vue'
import { isLoggedIn } from './auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', name: 'home', component: HomeView },
    { path: '/tentang', name: 'about', component: AboutView },
    { path: '/login', name: 'login', component: LoginView },
    { path: '/buat', name: 'create', component: CreateView, meta: { requiresAuth: true } },
    { path: '/isi/:id', name: 'fill', component: FillView },
    { path: '/hasil/:id', name: 'result', component: ResultView, meta: { requiresAuth: true } },
    { path: '/edit/:id', name: 'edit', component: CreateView, meta: { requiresAuth: true } },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
  scrollBehavior: () => ({ top: 0 }),
})

router.beforeEach((to) => {
  if (to.meta.requiresAuth && !isLoggedIn.value) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
  if (to.name === 'login' && isLoggedIn.value) return { name: 'home' }
})

export default router
