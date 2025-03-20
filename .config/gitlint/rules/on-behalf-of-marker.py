from gitlint.rules import LineRule, RuleViolation, CommitMessageTitle, CommitRule

class BodyContainsOnBehalfOfSAPMarker(CommitRule):
  """Enforce that each commit coming from an SAP contractor contains an
  "On-behalf-of SAP user@sap.com" marker.
  """

  # A rule MUST have a human friendly name
  name = "body-requires-on-behalf-of-sap"

  # A rule MUST have a *unique* id
  # We recommend starting with UC (for User-defined Commit-rule).
  id = "UC-sap"

  # Lower-case list of contractors
  contractors = [
    "@cyberus-technology.de"
  ]

  # Marker followed by " name.surname@sap.com"
  marker = "On-behalf-of: SAP"

  def validate(self, commit):
    if "@sap.com" in commit.author_email.lower():
      return

    # Allow third-party open-source contributions
    if not any(contractor in commit.author_email.lower() for contractor in self.contractors):
      return

    for line in commit.message.body:
      if line.startswith(self.marker) and "@sap.com" in line.lower():
        return

    msg = f"Body does not contain a '{self.marker} user@sap.com' line"
    return [RuleViolation(self.id, msg, line_nr=1)]
