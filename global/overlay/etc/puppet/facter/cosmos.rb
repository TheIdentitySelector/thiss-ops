#
# Extract local Cosmos configuration
#
require 'facter'
Facter.add(:cosmos_repo) do
  setcode do
    Facter::Util::Resolution.exec("sh -c '. /etc/cosmos/cosmos.conf && echo $COSMOS_REPO'")
  end
end

Facter.add(:cosmos_tag_pattern) do
  setcode do
    Facter::Util::Resolution.exec("sh -c '. /etc/cosmos/cosmos.conf && echo $COSMOS_UPDATE_VERIFY_GIT_TAG_PATTERN'")
  end
end

Facter.add(:cosmos_repo_origin_url) do
  setcode do
    Facter::Util::Resolution.exec("sh -c '. /etc/cosmos/cosmos.conf && cd $COSMOS_REPO && git remote show -n origin | grep \"Fetch URL\" | awk \"{print \\$NF }\"'")
  end
end

