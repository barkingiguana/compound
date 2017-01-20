describe file('/tmp/example-file') do
  it "exists" do
    expect(subject).to exist
  end
end
