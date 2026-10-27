<script setup>

import cheescuitImage from '../assets/img/cheescuit.png'
import sandoImage from '../assets/img/sando.png'

// ====== EDIT DATA DI SINI SAJA ======
const business = {
  name: 'Crave Bitte',
  tagline: 'Small Bites, Big Happiness',
  paragraphs: [
    'Crave Bitte adalah bisnis camilan yang menghadirkan perpaduan rasa gurihdan manis melalui Cheescuit dan Fruit Sando, dengan tampilan menarik untuk menemani momen kecil yang membahagiakan.',
    'Kuesioner di website ini kami buat untuk mendengar langsung pendapat pelanggan, supaya produk kami terus berkembang sesuai selera Anda.',
  ],
  vision: 'Menjadi merek dessert pilihan anak muda Indonesia yang di kenal karena kualitas, kreativitas, dan pengalaman menikmati produk yang berkesan.',
  mission: [
    'Menyediakan produk dessert berkualitas tinggi dengan bahan terbaik',
    'Menghadirkan inovasi rasa yang mengikuti tren pasar',
    'Menjaga konsistensi kualitas produk dan kepuasan pelanggan',
  ],
}

const products = [
  {
    image: cheescuitImage,
    name: 'Cheesecuit',
    desc: 'Dessert berbahan dasar cream cheese yang dipadukan dengan remas biskuit serta buah segar pilihan sehingga menciptakan cita rasa creamy, manis, dan segar dalam satu sajian.',
    price: 'Rp 12.000',
  },
  {
    image: sandoImage,
    name: 'Sando',
    desc: 'Japanese Fruit Sandwich yang dibuat menggunakan roti lembut, krim premium, dan buah pilihan segar sehingga menghasilkan perpaduan rasa yang manis, ringan, dan menyegarkan.',
    price: 'Rp 11.000',
  },
]

const contact = {
  email: 'cravebite@gmail.com',
  whatsapp: '6283857303697',
  whatsappLabel: '0838-5730-3697',
  instagram: '@cravebite.22.id',
  address: 'Universitas Bina Sarana Informatika, Margonda - Depok  ',
  hours: 'Senin – Sabtu, 09.00 – 17.00 WIB'
}
// ====================================

function initials(name) {
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join('')
}
</script>

<template>
  <!-- Tentang -->
  <section class="about-hero">
    <h1>Tentang {{ business.name }}</h1>
    <p class="about-tagline">{{ business.tagline }}</p>
  </section>

  <section class="card">
    <h2>Tentang Bisnis Kami</h2>
    <p v-for="(p, i) in business.paragraphs" :key="i">{{ p }}</p>

    <div class="about-grid">
      <div class="about-box">
        <h3>Visi</h3>
        <p style="margin: 0">{{ business.vision }}</p>
      </div>
      <div class="about-box">
        <h3>Misi</h3>
        <ul class="about-list">
          <li v-for="m in business.mission" :key="m">{{ m }}</li>
        </ul>
      </div>
    </div>
  </section>

  <!-- Produk -->
  <section>
    <h2 class="about-heading">Produk Kami</h2>
    <div class="about-grid">
      <article v-for="p in products" :key="p.name" class="card product">
        <img class="product-image" :src="p.image" :alt="p.name" />
        <h3>{{ p.name }}</h3>
        <p class="muted">{{ p.desc }}</p>
        <strong class="product-price">{{ p.price }}</strong>
      </article>
    </div>
  </section>

  <!-- Kontak -->
  <section class="card" id="kontak">
    <h2>Kontak</h2>
    <p class="muted">Ada pertanyaan, saran, atau ingin memesan? Hubungi kami.</p>
    <ul class="contact-list">
      <li>
        <span>✉️ Email</span>
        <a :href="`mailto:${contact.email}`">{{ contact.email }}</a>
      </li>
      <li>
        <span>💬 WhatsApp</span>
        <a :href="`https://wa.me/${contact.whatsapp}`" target="_blank" rel="noopener">{{ contact.whatsappLabel }}</a>
      </li>
      <li>
        <span>📸 Instagram</span>
        <a :href="`https://instagram.com/${contact.instagram}`" target="_blank" rel="noopener">@{{ contact.instagram
          }}</a>
      </li>
      <li>
        <span>📍 Alamat</span>
        <span>{{ contact.address }}</span>
      </li>
      <li>
        <span>🕘 Jam operasional</span>
        <span>{{ contact.hours }}</span>
      </li>
    </ul>
  </section>
</template>

<style scoped>
.about-hero {
  text-align: center;
  padding: 12px 0 24px;
}

.about-tagline {
  font-size: 1.1rem;
  color: var(--muted);
  margin: 0;
}

.about-heading {
  margin: 28px 0 12px;
}

.about-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 14px;
  margin-top: 14px;
}

.about-box {
  background: var(--accent-soft);
  border-radius: 12px;
  padding: 16px;
}

.about-box h3 {
  color: var(--accent-dark);
}

.about-list {
  margin: 0;
  padding-left: 18px;
}

.about-list li {
  margin-bottom: 4px;
}

.product {
  text-align: center;
  margin-bottom: 0;
}

.product-image {
  display: block;
  width: 260px;
  height: 260px;
  object-fit: contain;
  margin: 0 auto 8px;
}

.product-price {
  color: var(--accent-dark);
  font-size: 1.05rem;
}

.member-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
  gap: 14px;
}

.member {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  text-align: center;
  margin-bottom: 0;
}

.avatar {
  width: 84px;
  height: 120px;
  border-radius: 10px;
  object-fit: cover;
  margin-bottom: 8px;
}

.avatar-fallback {
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--accent-soft);
  color: var(--accent-dark);
  font-weight: 800;
  font-size: 1.5rem;
}

.contact-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.contact-list li {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  padding: 10px 0;
  border-top: 1px solid var(--border);
  flex-wrap: wrap;
}

.contact-list li>span:first-child {
  font-weight: 600;
}

.contact-list li> :last-child {
  text-align: right;
}

@media (max-width: 520px) {
  .contact-list li> :last-child {
    text-align: left;
  }
}
</style>
