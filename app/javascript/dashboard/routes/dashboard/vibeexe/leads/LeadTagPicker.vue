<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import LabelItem from 'dashboard/components-next/label/LabelItem.vue';
import AddLabel from 'dashboard/components-next/label/AddLabel.vue';
import VibeExeCrmAPI from 'dashboard/api/vibeexeCrm';

const props = defineProps({
  leadId: { type: [Number, String], required: true },
});

const store = useStore();
const allLabels = useMapGetter('labels/getLabels');
const selectedLabels = ref([]);
const hoveredLabel = ref(null);

const menuItems = computed(() =>
  allLabels.value.map(label => ({
    label: label.title,
    value: label.id,
    thumbnail: { name: label.title, color: label.color },
    isSelected: selectedLabels.value.some(selected => selected.id === label.id),
    action: 'leadLabel',
  }))
);

const fetchTags = async () => {
  const { data } = await VibeExeCrmAPI.getLeadTags(props.leadId);
  selectedLabels.value = data.tags || [];
};

const toggleLabel = async ({ value }) => {
  try {
    const selected = selectedLabels.value.some(label => label.id === value);
    const { data } = selected
      ? await VibeExeCrmAPI.removeLeadTag(props.leadId, value)
      : await VibeExeCrmAPI.addLeadTag(props.leadId, value);
    selectedLabels.value = data.tags || [];
  } catch (error) {
    useAlert(error.response?.data?.error || 'Could not update lead tags');
  }
};

watch(() => props.leadId, fetchTags);
onMounted(async () => {
  if (!allLabels.value.length) await store.dispatch('labels/get');
  await fetchTags();
});
</script>

<template>
  <div class="flex flex-wrap items-center gap-2" @mouseleave="hoveredLabel = null">
    <LabelItem
      v-for="label in selectedLabels"
      :key="label.id"
      :label="label"
      :is-hovered="hoveredLabel === label.id"
      @remove="toggleLabel({ value: label.id })"
      @hover="hoveredLabel = label.id"
    />
    <AddLabel :label-menu-items="menuItems" @update-label="toggleLabel" />
  </div>
</template>
