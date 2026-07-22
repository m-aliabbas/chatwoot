<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import SelectInput from 'dashboard/components-next/select/Select.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import VibeExeCrmAPI from 'dashboard/api/vibeexeCrm';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const isFetching = ref(false);
const isSaving = ref(false);
const pipelines = ref([]);
const form = ref({
  lead_creation_mode: 'manual',
  default_pipeline_id: '',
  default_stage_id: '',
  default_owner_id: '',
  default_team_id: '',
});

const agents = computed(() => store.getters['agents/getAgents'] || []);
const teams = computed(() => store.getters['teams/getTeams'] || []);
const modeOptions = computed(() => [
  { value: 'never', label: t('VIBEEXE_CRM.LEAD_CONFIG.MODE_NEVER') },
  { value: 'manual', label: t('VIBEEXE_CRM.LEAD_CONFIG.MODE_MANUAL') },
  { value: 'automatic', label: t('VIBEEXE_CRM.LEAD_CONFIG.MODE_AUTOMATIC') },
]);
const pipelineOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.LEAD_CONFIG.NONE') },
  ...pipelines.value.map(pipeline => ({
    value: pipeline.id,
    label: pipeline.name,
  })),
]);
const ownerOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.LEAD_CONFIG.NONE') },
  ...agents.value.map(agent => ({
    value: agent.id,
    label: agent.name || agent.email,
  })),
]);
const stageOptions = computed(() => {
  const pipeline = pipelines.value.find(
    item => item.id === Number(form.value.default_pipeline_id)
  );
  return [
    { value: '', label: t('VIBEEXE_CRM.LEAD_CONFIG.NONE') },
    ...(pipeline?.stages || []).map(stage => ({
      value: stage.id,
      label: stage.name,
    })),
  ];
});
const teamOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.LEAD_CONFIG.NONE') },
  ...teams.value.map(team => ({
    value: team.id,
    label: team.name,
  })),
]);

const applyConfig = config => {
  form.value = {
    lead_creation_mode: config.lead_creation_mode || 'manual',
    default_pipeline_id: config.default_pipeline_id || '',
    default_stage_id: config.default_stage_id || '',
    default_owner_id: config.default_owner_id || '',
    default_team_id: config.default_team_id || '',
  };
};

const fetchConfig = async () => {
  if (!props.inbox?.id) return;

  isFetching.value = true;
  try {
    const [{ data: config }, { data: pipelineList }] = await Promise.all([
      VibeExeCrmAPI.getInboxLeadConfig(props.inbox.id),
      VibeExeCrmAPI.getPipelines(),
    ]);
    pipelines.value = pipelineList;
    applyConfig(config);
  } finally {
    isFetching.value = false;
  }
};

const saveConfig = async () => {
  isSaving.value = true;
  try {
    const { data } = await VibeExeCrmAPI.updateInboxLeadConfig(
      props.inbox.id,
      form.value
    );
    applyConfig(data);
    useAlert(t('VIBEEXE_CRM.LEAD_CONFIG.SUCCESS'));
  } catch (error) {
    useAlert(
      error.message || t('VIBEEXE_CRM.LEAD_CONFIG.ERROR')
    );
  } finally {
    isSaving.value = false;
  }
};

watch(() => props.inbox?.id, fetchConfig);
watch(
  () => form.value.default_pipeline_id,
  (pipelineId, previousPipelineId) => {
    const selectedStageIsValid = stageOptions.value.some(
      option => option.value === Number(form.value.default_stage_id)
    );
    if (
      previousPipelineId !== undefined &&
      pipelineId !== previousPipelineId &&
      !selectedStageIsValid
    ) {
      form.value.default_stage_id = '';
    }
  }
);

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('teams/get');
  fetchConfig();
});
</script>

<template>
  <div class="max-w-4xl">
    <div class="flex flex-col gap-1 mb-6">
      <h3 class="text-heading-2 text-n-slate-12">
        {{ $t('VIBEEXE_CRM.LEAD_CONFIG.TITLE') }}
      </h3>
      <p class="text-body-2 text-n-slate-11 mb-0">
        {{ $t('VIBEEXE_CRM.LEAD_CONFIG.DESCRIPTION') }}
      </p>
    </div>

    <div class="flex flex-col gap-5">
      <label class="grid grid-cols-1 md:grid-cols-[14rem_1fr] gap-2 md:gap-6 items-center">
        <span class="text-sm font-medium text-n-slate-12">
          {{ $t('VIBEEXE_CRM.LEAD_CONFIG.MODE') }}
        </span>
        <SelectInput
          v-model="form.lead_creation_mode"
          :options="modeOptions"
          :disabled="isFetching"
        />
      </label>

      <label class="grid grid-cols-1 md:grid-cols-[14rem_1fr] gap-2 md:gap-6 items-center">
        <span class="text-sm font-medium text-n-slate-12">
          {{ $t('VIBEEXE_CRM.LEAD_CONFIG.PIPELINE') }}
        </span>
        <SelectInput
          v-model="form.default_pipeline_id"
          :options="pipelineOptions"
          :disabled="isFetching"
        />
      </label>

      <label class="grid grid-cols-1 md:grid-cols-[14rem_1fr] gap-2 md:gap-6 items-center">
        <span class="text-sm font-medium text-n-slate-12">
          {{ $t('VIBEEXE_CRM.LEAD_CONFIG.STAGE') }}
        </span>
        <SelectInput
          v-model="form.default_stage_id"
          :options="stageOptions"
          :disabled="isFetching || !form.default_pipeline_id"
        />
      </label>

      <label class="grid grid-cols-1 md:grid-cols-[14rem_1fr] gap-2 md:gap-6 items-center">
        <span class="text-sm font-medium text-n-slate-12">
          {{ $t('VIBEEXE_CRM.LEAD_CONFIG.OWNER') }}
        </span>
        <SelectInput
          v-model="form.default_owner_id"
          :options="ownerOptions"
          :disabled="isFetching"
        />
      </label>

      <label class="grid grid-cols-1 md:grid-cols-[14rem_1fr] gap-2 md:gap-6 items-center">
        <span class="text-sm font-medium text-n-slate-12">
          {{ $t('VIBEEXE_CRM.LEAD_CONFIG.TEAM') }}
        </span>
        <SelectInput
          v-model="form.default_team_id"
          :options="teamOptions"
          :disabled="isFetching"
        />
      </label>
    </div>

    <div class="flex justify-end mt-6">
      <NextButton
        :label="$t('VIBEEXE_CRM.LEAD_CONFIG.SAVE')"
        :is-loading="isSaving"
        @click="saveConfig"
      />
    </div>
  </div>
</template>
