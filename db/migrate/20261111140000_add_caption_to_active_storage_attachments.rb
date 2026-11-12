# Caption shown under each evidence image in the LaTeX reports.
class AddCaptionToActiveStorageAttachments < ActiveRecord::Migration[8.1]
  def change
    add_column :active_storage_attachments, :caption, :text
  end
end
