<script setup>
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import {
  Chart,
  BarController,
  BarElement,
  CategoryScale,
  LinearScale,
  Tooltip,
} from 'chart.js'

Chart.register(BarController, BarElement, CategoryScale, LinearScale, Tooltip)

const props = defineProps({
  labels: { type: Array, required: true },
  values: { type: Array, required: true },
  horizontal: { type: Boolean, default: false },
  color: { type: String, default: '#e8590c' },
  height: { type: Number, default: 260 },
})

const canvas = ref(null)
let chart = null

function buildConfig() {
  const axisText = '#6b7280'
  const grid = '#eceae6'
  const countAxis = {
    beginAtZero: true,
    ticks: { precision: 0, color: axisText },
    grid: { color: grid },
  }
  const labelAxis = { ticks: { color: axisText }, grid: { display: false } }

  return {
    type: 'bar',
    data: {
      labels: props.labels,
      datasets: [
        {
          label: 'Jumlah',
          data: props.values,
          backgroundColor: props.color,
          borderRadius: 6,
          maxBarThickness: 48,
        },
      ],
    },
    options: {
      indexAxis: props.horizontal ? 'y' : 'x',
      responsive: true,
      maintainAspectRatio: false,
      animation: { duration: 400 },
      plugins: { legend: { display: false } },
      scales: props.horizontal
        ? { x: countAxis, y: labelAxis }
        : { x: labelAxis, y: countAxis },
    },
  }
}

onMounted(() => {
  chart = new Chart(canvas.value, buildConfig())
})

watch(
  () => [props.labels, props.values],
  () => {
    if (!chart) return
    chart.data.labels = props.labels
    chart.data.datasets[0].data = props.values
    chart.update()
  },
  { deep: true },
)

onBeforeUnmount(() => chart?.destroy())
</script>

<template>
  <div class="chart-box" :style="{ height: height + 'px' }">
    <canvas ref="canvas" />
  </div>
</template>
