<script setup>
defineProps({
  label: { type: String, required: true },
  value: { type: [String, Number], default: '' },
});
</script>

<template>
  <div class="min-w-0 rounded-lg border border-n-weak bg-n-surface-2 px-3 py-3">
    <dt class="mb-1 text-xs font-medium text-n-slate-10">{{ label }}</dt>
    <dd class="mb-0 truncate text-sm font-medium text-n-slate-12">
      <slot>
        <span v-if="value">{{ value }}</span>
        <span v-else class="font-normal text-n-slate-10">—</span>
      </slot>
    </dd>
  </div>
</template>
