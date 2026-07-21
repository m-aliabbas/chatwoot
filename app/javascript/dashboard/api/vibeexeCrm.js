/* global axios */
import ApiClient from './ApiClient';

class VibeExeCrmAPI extends ApiClient {
  constructor() {
    super('vibeexe/crm', { accountScoped: true });
  }

  getPipelines() {
    return axios.get(`${this.url}/pipelines`);
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
