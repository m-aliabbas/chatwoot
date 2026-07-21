<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import VibeExeCrmAPI from 'dashboard/api/vibeexeCrm';

const props = defineProps({
  conversationId: {
    type: [String, Number],
    required: true,
  },
});

const { t } = useI18n();
const router = useRouter();

const linkedLeads = ref([]);
const compatibleLeads = ref([]);
const ambiguous = ref(false);
const showCompatibleLeads = ref(false);
const isLoading = ref(false);
const isUpdating = ref(false);
const leadCreationMode = ref('manual');

const hasLinkedLeads = computed(() => linkedLeads.value.length > 0);
const canManageLinks = computed(() => leadCreationMode.value !== 'never');

const fetchLinkedLeads = async () => {
  if (!props.conversationId) return;

  isLoading.value = true;
  try {
    const { data } = await VibeExeCrmAPI.getConversationLeads(
      props.conversationId
    );
    linkedLeads.value = data.leads || [];
    ambiguous.value = data.ambiguous || false;
    leadCreationMode.value = data.lead_creation_mode || 'manual';
  } finally {
    isLoading.value = false;
  }
};

const fetchCompatibleLeads = async () => {
  const { data } = await VibeExeCrmAPI.getCompatibleConversationLeads(
    props.conversationId
  );
  compatibleLeads.value = data.leads || [];
  ambiguous.value = data.ambiguous || ambiguous.value;
  leadCreationMode.value = data.lead_creation_mode || leadCreationMode.value;
};

const createLead = async () => {
  isUpdating.value = true;
  try {
    const { data } = await VibeExeCrmAPI.createLeadFromConversation(
      props.conversationId
    );
    linkedLeads.value = data.linked_leads || [];
    showCompatibleLeads.value = false;
    useAlert(t('VIBEEXE_CRM.LEADS.CREATED'));
  } catch (error) {
    useAlert(error.message || t('VIBEEXE_CRM.LEADS.ERROR'));
  } finally {
    isUpdating.value = false;
  }
};

const toggleCompatibleLeads = async () => {
  showCompatibleLeads.value = !showCompatibleLeads.value;
  if (showCompatibleLeads.value) {
    await fetchCompatibleLeads();
  }
};

const linkLead = async lead => {
  isUpdating.value = true;
  try {
    const { data } = await VibeExeCrmAPI.linkLeadToConversation(
      props.conversationId,
      lead.id
    );
    linkedLeads.value = data.linked_leads || [];
    showCompatibleLeads.value = false;
    useAlert(t('VIBEEXE_CRM.LEADS.LINKED'));
  } catch (error) {
    useAlert(error.message || t('VIBEEXE_CRM.LEADS.ERROR'));
  } finally {
    isUpdating.value = false;
  }
};

const unlinkLead = async lead => {
  isUpdating.value = true;
  try {
    const { data } = await VibeExeCrmAPI.unlinkLeadFromConversation(
      props.conversationId,
      lead.id
    );
    linkedLeads.value = data.linked_leads || [];
    useAlert(t('VIBEEXE_CRM.LEADS.UNLINKED'));
  } catch (error) {
    useAlert(error.message || t('VIBEEXE_CRM.LEADS.ERROR'));
  } finally {
    isUpdating.value = false;
  }
};

const openLead = lead => {
  router.push({ name: 'lead_show', params: { leadId: lead.id } });
};

watch(() => props.conversationId, fetchLinkedLeads);
onMounted(fetchLinkedLeads);
</script>

<template>
  <section class="border-b border-n-weak px-0 py-3">
    <div class="flex items-center justify-between gap-2 mb-2">
      <h4 class="text-sm font-medium text-n-slate-12 mb-0">
        {{ $t('VIBEEXE_CRM.LEADS.TITLE') }}
      </h4>
      <div class="flex items-center gap-1">
        <NextButton
          v-if="!hasLinkedLeads && canManageLinks"
          ghost
          slate
          xs
          icon="i-lucide-plus"
          :label="$t('VIBEEXE_CRM.LEADS.CREATE')"
          :is-loading="isUpdating"
          @click="createLead"
        />
        <NextButton
          v-if="canManageLinks"
          ghost
          slate
          xs
          icon="i-lucide-link"
          :label="$t('VIBEEXE_CRM.LEADS.LINK')"
          :disabled="isUpdating"
          @click="toggleCompatibleLeads"
        />
      </div>
    </div>

    <p
      v-if="ambiguous && !hasLinkedLeads"
      class="text-xs text-n-amber-11 mb-2"
    >
      {{ $t('VIBEEXE_CRM.LEADS.AMBIGUOUS') }}
    </p>

    <p v-if="isLoading" class="text-xs text-n-slate-11 mb-0">
      {{ $t('VIBEEXE_CRM.LEADS.LOADING') }}
    </p>
    <p
      v-else-if="!hasLinkedLeads"
      class="text-xs text-n-slate-11 mb-0"
    >
      {{ $t('VIBEEXE_CRM.LEADS.EMPTY') }}
    </p>

    <div v-else class="flex flex-col gap-2">
      <div
        v-for="lead in linkedLeads"
        :key="lead.id"
        class="flex items-start justify-between gap-2 rounded-md border border-n-weak p-2"
      >
        <div class="min-w-0">
          <p class="text-sm text-n-slate-12 truncate mb-0">
            {{ lead.title }}
          </p>
          <p class="text-xs text-n-slate-11 truncate mb-0">
            {{ lead.pipeline_name }} · {{ lead.pipeline_stage_name }}
          </p>
        </div>
        <div class="flex items-center gap-1">
          <NextButton
            ghost
            slate
            xs
            icon="i-lucide-external-link"
            :label="$t('VIBEEXE_CRM.LEADS.OPEN')"
            @click="openLead(lead)"
          />
          <NextButton
            ghost
            ruby
            xs
            icon="i-lucide-unlink"
            :label="$t('VIBEEXE_CRM.LEADS.UNLINK')"
            :disabled="isUpdating"
            @click="unlinkLead(lead)"
          />
        </div>
      </div>
    </div>

    <div v-if="showCompatibleLeads" class="mt-3 flex flex-col gap-2">
      <p
        v-if="compatibleLeads.length === 0"
        class="text-xs text-n-slate-11 mb-0"
      >
        {{ $t('VIBEEXE_CRM.LEADS.NO_COMPATIBLE') }}
      </p>
      <div
        v-for="lead in compatibleLeads"
        :key="lead.id"
        class="flex items-center justify-between gap-2 rounded-md border border-n-weak p-2"
      >
        <div class="min-w-0">
          <p class="text-sm text-n-slate-12 truncate mb-0">
            {{ lead.title }}
          </p>
          <p class="text-xs text-n-slate-11 truncate mb-0">
            {{ lead.pipeline_name }} · {{ lead.pipeline_stage_name }}
          </p>
        </div>
        <NextButton
          faded
          blue
          xs
          icon="i-lucide-link"
          :label="$t('VIBEEXE_CRM.LEADS.LINK')"
          :disabled="isUpdating"
          @click="linkLead(lead)"
        />
      </div>
    </div>
  </section>
</template>
