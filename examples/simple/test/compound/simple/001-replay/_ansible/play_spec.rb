describe 'ansible-playbook' do
  subject { BarkingIguana::Compound::Ansible::ResultsParser.new(ENV['ANSIBLE_RESULTS_FILE']) }

  it "did not change anything" do
    expect(subject.recap.total_changes).to eq 0
  end
end
