class VibeExe::Crm::UpdateLeadTagService
  def initialize(lead:, label:, user:)
    @lead = lead
    @label = label
    @user = user
  end

  def add
    update('tag_added') { @lead.label_list.add(@label.title) }
  end

  def remove
    update('tag_removed') { @lead.label_list.remove(@label.title) }
  end

  private

  def update(activity_type)
    changed = false
    @lead.transaction do
      previous_labels = @lead.label_list.to_a
      yield
      changed = previous_labels != @lead.label_list.to_a
      next unless changed

      @lead.save!
      @lead.activities.create!(
        account: @lead.account,
        user: @user,
        activity_type: activity_type,
        metadata: { label_id: @label.id, label_name: @label.title, label_color: @label.color }
      )
      @lead.update_column(:last_activity_at, Time.current)
    end
    changed
  end
end
