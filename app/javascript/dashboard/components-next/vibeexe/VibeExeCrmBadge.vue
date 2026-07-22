<script setup>
import { computed } from 'vue';

const props = defineProps({
  value: { type: String, default: '' },
  type: { type: String, default: 'neutral' },
});

const label = computed(() => {
  if (!props.value) return '—';
  return props.value.replaceAll('_', ' ').replace(/^./, character => character.toUpperCase());
});

const colorClass = computed(() => {
  const colors = {
    open: 'bg-n-blue-3 text-n-blue-11 ring-n-blue-7',
    won: 'bg-n-teal-3 text-n-teal-11 ring-n-teal-7',
    lost: 'bg-n-ruby-3 text-n-ruby-11 ring-n-ruby-7',
    archived: 'bg-n-slate-3 text-n-slate-11 ring-n-slate-7',
    low: 'bg-n-slate-3 text-n-slate-11 ring-n-slate-7',
    medium: 'bg-n-amber-3 text-n-amber-11 ring-n-amber-7',
    high: 'bg-n-orange-3 text-n-orange-11 ring-n-orange-7',
    urgent: 'bg-n-ruby-3 text-n-ruby-11 ring-n-ruby-7',
  };
  return colors[props.value?.toLowerCase()] ||
    (props.type === 'accent'
      ? 'bg-n-blue-3 text-n-blue-11 ring-n-blue-7'
      : 'bg-n-slate-3 text-n-slate-11 ring-n-slate-7');
});
</script>

<template>
  <span
    class="inline-flex w-fit max-w-full items-center rounded-md px-2 py-0.5 text-xs font-medium capitalize ring-1 ring-inset"
    :class="colorClass"
  >
    <span class="truncate">{{ label }}</span>
  </span>
</template>
