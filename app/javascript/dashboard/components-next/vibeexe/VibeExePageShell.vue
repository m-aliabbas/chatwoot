<script setup>
defineProps({
  title: {
    type: String,
    required: true,
  },
  subtitle: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-y-auto bg-n-background">
    <header class="border-b border-n-weak bg-n-surface-1">
      <div class="max-w-7xl px-4 py-6 mx-auto sm:px-6 lg:px-8">
        <h1 class="text-2xl font-semibold leading-8 text-n-slate-12">
          {{ title }}
        </h1>
        <p v-if="subtitle" class="mt-1 text-sm leading-6 text-n-slate-11">
          {{ subtitle }}
        </p>
      </div>
    </header>
    <div class="flex-1 w-full max-w-7xl px-4 py-6 mx-auto sm:px-6 lg:px-8">
      <slot />
    </div>
  </section>
</template>
