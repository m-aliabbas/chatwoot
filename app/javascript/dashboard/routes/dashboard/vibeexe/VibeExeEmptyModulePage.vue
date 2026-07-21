<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import VibeExePageShell from 'dashboard/components-next/vibeexe/VibeExePageShell.vue';

const { t } = useI18n();
const route = useRoute();

const moduleKey = computed(() => route.meta?.vibeexeModule || 'TASKS');
</script>

<template>
  <VibeExePageShell
    :title="t(`VIBEEXE_EMPTY.${moduleKey}.TITLE`)"
    :subtitle="t(`VIBEEXE_EMPTY.${moduleKey}.SUBTITLE`)"
  >
    <section class="rounded-lg border border-n-weak bg-n-surface-1 p-6">
      <div class="mx-auto grid max-w-xl justify-items-center gap-3 text-center">
        <span class="i-lucide-construction size-8 text-n-slate-10" />
        <h2 class="text-base font-medium text-n-slate-12">
          {{ t(`VIBEEXE_EMPTY.${moduleKey}.HEADING`) }}
        </h2>
        <p class="text-sm leading-6 text-n-slate-11">
          {{ t(`VIBEEXE_EMPTY.${moduleKey}.DESCRIPTION`) }}
        </p>
      </div>
    </section>
  </VibeExePageShell>
</template>
