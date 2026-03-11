require "rails_helper"

RSpec.describe OrganizationInvitationMailer, type: :mailer do
  describe "#invite" do
    let(:organization) { create(:organization, name: "Acme Corp") }
    let(:inviter) { create(:user, first_name: "John", last_name: "Doe") }
    let(:invitation) do
      ActsAsTenant.with_tenant(organization) do
        create(:organization_invitation,
               organization: organization,
               invited_by: inviter,
               email: "newuser@example.com",
               role: "member")
      end
    end
    let(:mail) { OrganizationInvitationMailer.invite(invitation) }

    it "renders the subject" do
      expect(mail.subject).to eq("You've been invited to join Acme Corp on PromptTracker")
    end

    it "sends to the invited email" do
      expect(mail.to).to eq(["newuser@example.com"])
    end

    it "sends from the default email" do
      expect(mail.from).to eq(["from@example.com"])
    end

    it "includes the organization name in the body" do
      expect(mail.body.encoded).to match("Acme Corp")
    end

    it "includes the inviter's name in the body" do
      expect(mail.body.encoded).to match("John Doe")
    end

    it "includes the role in the body" do
      expect(mail.body.encoded).to match("Member")
    end

    it "includes the invitation link in the body" do
      expect(mail.body.encoded).to match(invitation.token)
    end

    it "includes the expiration date in the body" do
      expect(mail.body.encoded).to match(invitation.expires_at.strftime("%B %d, %Y"))
    end

    context "with different roles" do
      it "includes admin role" do
        ActsAsTenant.with_tenant(organization) do
          invitation.update!(role: "admin")
        end
        mail = OrganizationInvitationMailer.invite(invitation)
        expect(mail.body.encoded).to match(/Admin/i)
      end

      it "includes viewer role" do
        ActsAsTenant.with_tenant(organization) do
          invitation.update!(role: "viewer")
        end
        mail = OrganizationInvitationMailer.invite(invitation)
        expect(mail.body.encoded).to match(/Viewer/i)
      end
    end
  end
end
