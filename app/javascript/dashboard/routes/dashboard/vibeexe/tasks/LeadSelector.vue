<script setup>
import { computed, ref, watch } from 'vue';
import { useDebounceFn } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import VibeExeCrmAPI from 'dashboard/api/vibeexeCrm';

const props = defineProps({
  modelValue: { type: [String, Number], default: '' },
  disabled: { type: Boolean, default: false },
});

const emit = defineEmits(['update:modelValue']);
const { t } = useI18n();
const leads = ref([]);
const selectedLead = ref(null);
const isLoading = ref(false);
let searchRequest = 0;

const leadLabel = lead => {
  const contact = lead.contact?.name || t('VIBEEXE_CRM.WORKSPACE.UNKNOWN_CONTACT');
  return `${lead.title} · ${contact} · ${lead.pipeline_name}`;
};

const options = computed(() => {
  const records = [...leads.value];
  if (selectedLead.value && !records.some(lead => lead.id === selectedLead.value.id)) {
    records.unshift(selectedLead.value);
  }
  return records.map(lead => ({ value: lead.id, label: leadLabel(lead) }));
});

const displayLabel = computed(() =>
  selectedLead.value ? leadLabel(selectedLead.value) : ''
);
const emptyState = computed(() =>
  isLoading.value
    ? t('VIBEEXE_CRM.TASKS.LEAD_SEARCHING')
    : t('VIBEEXE_CRM.TASKS.LEAD_SEARCH_EMPTY')
);

const fetchLeads = async query => {
  const request = ++searchRequest;
  isLoading.value = true;
  try {
    const { data } = await VibeExeCrmAPI.getLeads({
      q: query || undefined,
      page: 1,
      sort_by: 'last_activity_at',
      sort_direction: 'desc',
    });
    if (request === searchRequest) leads.value = data.leads || [];
  } finally {
    if (request === searchRequest) isLoading.value = false;
  }
};

const fetchSelectedLead = async leadId => {
  if (!leadId) {
    selectedLead.value = null;
    return;
  }
  const existing = leads.value.find(lead => lead.id === Number(leadId));
  if (existing) {
    selectedLead.value = existing;
    return;
  }
  const { data } = await VibeExeCrmAPI.getLead(leadId);
  selectedLead.value = data.lead;
};

const handleSearch = useDebounceFn(query => fetchLeads(query?.trim()), 300);
const handleSelect = value => {
  const id = value ? Number(value) : '';
  selectedLead.value = id
    ? leads.value.find(lead => lead.id === id) || selectedLead.value
    : null;
  emit('update:modelValue', id);
};

watch(() => props.modelValue, fetchSelectedLead, { immediate: true });
</script>

<template>
  <ComboBox
    :model-value="modelValue"
    :options="options"
    :display-label="displayLabel"
    :disabled="disabled"
    :placeholder="$t('VIBEEXE_CRM.TASKS.SELECT_LEAD')"
    :search-placeholder="$t('VIBEEXE_CRM.TASKS.LEAD_SEARCH_PLACEHOLDER')"
    :empty-state="emptyState"
    use-api-results
    class="[&>div>button]:min-h-10 [&>div>button]:h-auto [&>div>button]:text-left [&>div>div_ul]:max-h-72"
    @open="fetchLeads('')"
    @search="handleSearch"
    @update:model-value="handleSelect"
  />
</template>
