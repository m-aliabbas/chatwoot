/* global axios */
import ApiClient from './ApiClient';

class VibeExeCrmAPI extends ApiClient {
  constructor() {
    super('vibeexe/crm', { accountScoped: true });
  }

  getPipelines() {
    return axios.get(`${this.url}/pipelines`);
  }

  getAllPipelines() {
    return axios.get(`${this.url}/pipelines`, {
      params: { include_inactive: true },
    });
  }

  createPipeline(data) {
    return axios.post(`${this.url}/pipelines`, data);
  }

  updatePipeline(pipelineId, data) {
    return axios.patch(`${this.url}/pipelines/${pipelineId}`, data);
  }

  deletePipeline(pipelineId) {
    return axios.delete(`${this.url}/pipelines/${pipelineId}`);
  }

  bootstrapDefaultPipeline() {
    return axios.post(`${this.url}/pipelines/bootstrap_default`);
  }

  createStage(pipelineId, data) {
    return axios.post(`${this.url}/pipelines/${pipelineId}/stages`, data);
  }

  updateStage(pipelineId, stageId, data) {
    return axios.patch(`${this.url}/pipelines/${pipelineId}/stages/${stageId}`, data);
  }

  deleteStage(pipelineId, stageId) {
    return axios.delete(`${this.url}/pipelines/${pipelineId}/stages/${stageId}`);
  }

  reorderStages(pipelineId, stageIds) {
    return axios.patch(`${this.url}/pipelines/${pipelineId}/stages/reorder`, {
      stage_ids: stageIds,
    });
  }

  getLeads(params = {}) {
    return axios.get(`${this.url}/leads`, { params });
  }

  getLead(leadId) {
    return axios.get(`${this.url}/leads/${leadId}`);
  }

  createLead(data) {
    return axios.post(`${this.url}/leads`, data);
  }

  updateLead(leadId, data) {
    return axios.patch(`${this.url}/leads/${leadId}`, data);
  }

  archiveLead(leadId) {
    return axios.patch(`${this.url}/leads/${leadId}/archive`);
  }

  restoreLead(leadId) {
    return axios.patch(`${this.url}/leads/${leadId}/restore`);
  }

  markLeadWon(leadId) {
    return axios.patch(`${this.url}/leads/${leadId}/mark_won`);
  }

  markLeadLost(leadId, closedReason) {
    return axios.patch(`${this.url}/leads/${leadId}/mark_lost`, {
      closed_reason: closedReason,
    });
  }

  changeLeadStage(leadId, data) {
    return axios.patch(`${this.url}/leads/${leadId}/change_stage`, data);
  }

  getLeadBoard(params = {}) {
    return axios.get(`${this.url}/leads/board`, { params });
  }

  getLeadConversations(leadId) {
    return axios.get(`${this.url}/leads/${leadId}/conversations`);
  }

  linkConversationToLead(leadId, conversationId) {
    return axios.post(`${this.url}/leads/${leadId}/conversations`, {
      conversation_id: conversationId,
    });
  }

  unlinkConversationFromLead(leadId, conversationId) {
    return axios.delete(`${this.url}/leads/${leadId}/conversations/${conversationId}`);
  }

  getLeadActivities(leadId, params = {}) {
    return axios.get(`${this.url}/leads/${leadId}/activities`, { params });
  }

  addLeadNote(leadId, body, blobIds = []) {
    return axios.post(`${this.url}/leads/${leadId}/notes`, {
      body,
      blob_ids: blobIds,
    });
  }

  getLeadNotes(leadId, params = {}) {
    return axios.get(`${this.url}/leads/${leadId}/notes`, { params });
  }

  updateLeadNote(leadId, noteId, body) {
    return axios.patch(`${this.url}/leads/${leadId}/notes/${noteId}`, { body });
  }

  deleteLeadNote(leadId, noteId) {
    return axios.delete(`${this.url}/leads/${leadId}/notes/${noteId}`);
  }

  deleteLeadNoteAttachment(leadId, noteId, attachmentId) {
    return axios.delete(
      `${this.url}/leads/${leadId}/notes/${noteId}/attachments/${attachmentId}`
    );
  }

  getLeadTags(leadId) {
    return axios.get(`${this.url}/leads/${leadId}/tags`);
  }

  addLeadTag(leadId, labelId) {
    return axios.post(`${this.url}/leads/${leadId}/tags/${labelId}`);
  }

  removeLeadTag(leadId, labelId) {
    return axios.delete(`${this.url}/leads/${leadId}/tags/${labelId}`);
  }

  getTasks(params = {}) {
    return axios.get(`${this.url}/tasks`, { params });
  }

  getTask(taskId) {
    return axios.get(`${this.url}/tasks/${taskId}`);
  }

  createTask(data) {
    return axios.post(`${this.url}/tasks`, data);
  }

  updateTask(taskId, data) {
    return axios.patch(`${this.url}/tasks/${taskId}`, data);
  }

  completeTask(taskId, completionNote) {
    return axios.patch(`${this.url}/tasks/${taskId}/complete`, {
      completion_note: completionNote,
    });
  }

  cancelTask(taskId) {
    return axios.patch(`${this.url}/tasks/${taskId}/cancel`);
  }

  rescheduleTask(taskId, data) {
    return axios.patch(`${this.url}/tasks/${taskId}/reschedule`, data);
  }

  deleteTaskAttachment(taskId, attachmentId) {
    return axios.delete(
      `${this.url}/tasks/${taskId}/attachments/${attachmentId}`
    );
  }

  getLeadTasks(leadId, params = {}) {
    return axios.get(`${this.url}/leads/${leadId}/tasks`, { params });
  }

  createLeadTask(leadId, data) {
    return axios.post(`${this.url}/leads/${leadId}/tasks`, data);
  }

  getInboxLeadConfig(inboxId) {
    return axios.get(`${this.url}/inboxes/${inboxId}/lead_config`);
  }

  updateInboxLeadConfig(inboxId, data) {
    return axios.patch(`${this.url}/inboxes/${inboxId}/lead_config`, data);
  }

  getConversationLeads(conversationId) {
    return axios.get(`${this.url}/conversations/${conversationId}/leads`);
  }

  getCompatibleConversationLeads(conversationId) {
    return axios.get(
      `${this.url}/conversations/${conversationId}/leads/compatible`
    );
  }

  createLeadFromConversation(conversationId) {
    return axios.post(`${this.url}/conversations/${conversationId}/leads`);
  }

  linkLeadToConversation(conversationId, leadId) {
    return axios.post(`${this.url}/conversations/${conversationId}/leads/link`, {
      lead_id: leadId,
    });
  }

  unlinkLeadFromConversation(conversationId, leadId) {
    return axios.delete(
      `${this.url}/conversations/${conversationId}/leads/${leadId}/unlink`
    );
  }
}

export default new VibeExeCrmAPI();
