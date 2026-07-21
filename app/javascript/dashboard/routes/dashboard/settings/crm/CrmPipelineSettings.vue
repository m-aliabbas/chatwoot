<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import SelectInput from 'dashboard/components-next/select/Select.vue';
import VibeExeCrmAPI from 'dashboard/api/vibeexeCrm';

const { t } = useI18n();
const pipelines = ref([]);
const selectedPipelineId = ref('');
const pipelineForm = ref({ name: '', active: true, default: false, position: 0 });
const stageForm = ref({ name: '', active: true, default: false, position: 0, stage_type: 'open_stage', probability: 0 });
const isLoading = ref(false);

const selectedPipeline = computed(() =>
  pipelines.value.find(pipeline => pipeline.id === Number(selectedPipelineId.value))
);
const pipelineOptions = computed(() =>
  pipelines.value.map(pipeline => ({ value: pipeline.id, label: pipeline.name }))
);
const stageTypeOptions = computed(() => [
  { value: 'open_stage', label: t('VIBEEXE_CRM.SETTINGS.STAGE_OPEN') },
  { value: 'won_stage', label: t('VIBEEXE_CRM.SETTINGS.STAGE_WON') },
  { value: 'lost_stage', label: t('VIBEEXE_CRM.SETTINGS.STAGE_LOST') },
]);

const showError = error => useAlert(error?.response?.data?.error || error?.message || t('VIBEEXE_CRM.SETTINGS.ERROR'));

const fetchPipelines = async () => {
  isLoading.value = true;
  try {
    const { data } = await VibeExeCrmAPI.getAllPipelines();
    pipelines.value = data || [];
    if (!selectedPipelineId.value) {
      selectedPipelineId.value = pipelines.value[0]?.id || '';
    }
  } catch (error) {
    showError(error);
  } finally {
    isLoading.value = false;
  }
};

const savePipeline = async () => {
  try {
    const payload = { ...pipelineForm.value };
    if (selectedPipeline.value) {
      await VibeExeCrmAPI.updatePipeline(selectedPipeline.value.id, payload);
    } else {
      await VibeExeCrmAPI.createPipeline(payload);
    }
    pipelineForm.value = { name: '', active: true, default: false, position: 0 };
    await fetchPipelines();
    useAlert(t('VIBEEXE_CRM.SETTINGS.SAVED'));
  } catch (error) {
    showError(error);
  }
};

const editPipeline = pipeline => {
  selectedPipelineId.value = pipeline.id;
  pipelineForm.value = {
    name: pipeline.name,
    active: pipeline.active,
    default: pipeline.default,
    position: pipeline.position,
  };
};

const deactivatePipeline = async pipeline => {
  try {
    await VibeExeCrmAPI.updatePipeline(pipeline.id, { active: false });
    await fetchPipelines();
  } catch (error) {
    showError(error);
  }
};

const deletePipeline = async pipeline => {
  try {
    await VibeExeCrmAPI.deletePipeline(pipeline.id);
    await fetchPipelines();
  } catch (error) {
    showError(error);
  }
};

const bootstrapPipeline = async () => {
  try {
    await VibeExeCrmAPI.bootstrapDefaultPipeline();
    await fetchPipelines();
    useAlert(t('VIBEEXE_CRM.SETTINGS.BOOTSTRAPPED'));
  } catch (error) {
    showError(error);
  }
};

const saveStage = async () => {
  if (!selectedPipeline.value) return;
  try {
    await VibeExeCrmAPI.createStage(selectedPipeline.value.id, stageForm.value);
    stageForm.value = { name: '', active: true, default: false, position: 0, stage_type: 'open_stage', probability: 0 };
    await fetchPipelines();
    useAlert(t('VIBEEXE_CRM.SETTINGS.SAVED'));
  } catch (error) {
    showError(error);
  }
};

const updateStage = async (stage, changes) => {
  try {
    await VibeExeCrmAPI.updateStage(selectedPipeline.value.id, stage.id, changes);
    await fetchPipelines();
  } catch (error) {
    showError(error);
  }
};

const deleteStage = async stage => {
  try {
    await VibeExeCrmAPI.deleteStage(selectedPipeline.value.id, stage.id);
    await fetchPipelines();
  } catch (error) {
    showError(error);
  }
};

onMounted(fetchPipelines);
</script>

<template>
  <SettingsLayout :is-loading="isLoading">
    <div class="w-full">
      <BaseSettingsHeader
        :title="$t('VIBEEXE_CRM.SETTINGS.TITLE')"
        :description="$t('VIBEEXE_CRM.SETTINGS.DESCRIPTION')"
      >
        <template #actions>
          <NextButton
            icon="i-lucide-sparkles"
            :label="$t('VIBEEXE_CRM.SETTINGS.BOOTSTRAP')"
            @click="bootstrapPipeline"
          />
        </template>
      </BaseSettingsHeader>

      <div class="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-[20rem_1fr]">
        <section class="rounded-md border border-n-weak bg-n-surface-1 p-4">
          <h3 class="mb-3 text-base font-medium text-n-slate-12">
            {{ $t('VIBEEXE_CRM.SETTINGS.PIPELINES') }}
          </h3>
          <div class="flex flex-col gap-2">
            <button
              v-for="pipeline in pipelines"
              :key="pipeline.id"
              class="flex items-center justify-between gap-2 rounded-md border border-n-weak px-3 py-2 text-left text-sm"
              :class="pipeline.id === Number(selectedPipelineId) ? 'bg-n-alpha-2 text-n-slate-12' : 'text-n-slate-11'"
              @click="selectedPipelineId = pipeline.id"
            >
              <span class="truncate">{{ pipeline.name }}</span>
              <span v-if="pipeline.default" class="text-xs text-n-blue-11">{{ $t('VIBEEXE_CRM.SETTINGS.DEFAULT') }}</span>
            </button>
          </div>
        </section>

        <main class="flex flex-col gap-6">
          <section class="rounded-md border border-n-weak bg-n-surface-1 p-4">
            <h3 class="mb-3 text-base font-medium text-n-slate-12">
              {{ $t('VIBEEXE_CRM.SETTINGS.PIPELINE_FORM') }}
            </h3>
            <div class="grid grid-cols-1 gap-3 md:grid-cols-4">
              <Input v-model="pipelineForm.name" :label="$t('VIBEEXE_CRM.SETTINGS.NAME')" />
              <Input v-model="pipelineForm.position" type="number" :label="$t('VIBEEXE_CRM.SETTINGS.POSITION')" />
              <label class="flex items-center gap-2 text-sm text-n-slate-12">
                <input v-model="pipelineForm.active" type="checkbox" />
                {{ $t('VIBEEXE_CRM.SETTINGS.ACTIVE') }}
              </label>
              <label class="flex items-center gap-2 text-sm text-n-slate-12">
                <input v-model="pipelineForm.default" type="checkbox" />
                {{ $t('VIBEEXE_CRM.SETTINGS.DEFAULT') }}
              </label>
            </div>
            <div class="mt-4 flex flex-wrap gap-2">
              <NextButton icon="i-lucide-save" :label="$t('VIBEEXE_CRM.SETTINGS.SAVE_PIPELINE')" @click="savePipeline" />
              <NextButton v-if="selectedPipeline" outline slate icon="i-lucide-pencil" :label="$t('VIBEEXE_CRM.SETTINGS.EDIT_SELECTED')" @click="editPipeline(selectedPipeline)" />
              <NextButton v-if="selectedPipeline" outline amber icon="i-lucide-eye-off" :label="$t('VIBEEXE_CRM.SETTINGS.DEACTIVATE')" @click="deactivatePipeline(selectedPipeline)" />
              <NextButton v-if="selectedPipeline" outline ruby icon="i-lucide-trash-2" :label="$t('VIBEEXE_CRM.SETTINGS.DELETE')" @click="deletePipeline(selectedPipeline)" />
            </div>
          </section>

          <section class="rounded-md border border-n-weak bg-n-surface-1 p-4">
            <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
              <h3 class="mb-0 text-base font-medium text-n-slate-12">
                {{ $t('VIBEEXE_CRM.SETTINGS.STAGES') }}
              </h3>
              <SelectInput v-model="selectedPipelineId" :options="pipelineOptions" />
            </div>
            <div class="flex flex-col gap-2">
              <div
                v-for="stage in selectedPipeline?.stages || []"
                :key="stage.id"
                class="grid grid-cols-1 items-center gap-2 rounded-md border border-n-weak p-3 md:grid-cols-[1fr_9rem_7rem_7rem_auto]"
              >
                <Input :model-value="stage.name" @update:model-value="updateStage(stage, { name: $event })" />
                <SelectInput :model-value="stage.stage_type" :options="stageTypeOptions" @update:model-value="updateStage(stage, { stage_type: $event })" />
                <Input :model-value="stage.probability" type="number" @update:model-value="updateStage(stage, { probability: $event })" />
                <label class="flex items-center gap-2 text-sm text-n-slate-12">
                  <input :checked="stage.active" type="checkbox" @change="updateStage(stage, { active: $event.target.checked })" />
                  {{ $t('VIBEEXE_CRM.SETTINGS.ACTIVE') }}
                </label>
                <NextButton ghost ruby xs icon="i-lucide-trash-2" :label="$t('VIBEEXE_CRM.SETTINGS.DELETE')" @click="deleteStage(stage)" />
              </div>
            </div>
            <div class="mt-4 grid grid-cols-1 gap-3 md:grid-cols-[1fr_9rem_7rem_7rem_auto]">
              <Input v-model="stageForm.name" :placeholder="$t('VIBEEXE_CRM.SETTINGS.STAGE_NAME')" />
              <SelectInput v-model="stageForm.stage_type" :options="stageTypeOptions" />
              <Input v-model="stageForm.probability" type="number" />
              <Input v-model="stageForm.position" type="number" />
              <NextButton icon="i-lucide-plus" :label="$t('VIBEEXE_CRM.SETTINGS.ADD_STAGE')" @click="saveStage" />
            </div>
          </section>
        </main>
      </div>
    </div>
  </SettingsLayout>
</template>
