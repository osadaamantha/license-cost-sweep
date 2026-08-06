---
description: Grep the tree for prohibited Exchange/Graph/licence mutation cmdlets, interactive auth, and secret-shaped literals. Substitutes for the CI scan this repo doesn't have yet.
---

There is no CI in this repository, so this command is the manual stand-in for the mutation-cmdlet scan `license-cost-safety` requires. Run it whenever runtime, Exchange, or Graph code changes, and whenever asked to check safety compliance.

Search tracked, non-`.venv` files for:

1. **Prohibited Exchange/Graph/licence mutation cmdlets** in anything that looks like runtime code (not an explicitly-named onboarding/admin script): `Set-Mailbox`, `Set-CASMailbox`, `New-Mailbox`, `Remove-Mailbox`, `Enable-Mailbox`, `Disable-Mailbox`, `Set-MgUserLicense`, `Set-MsolUserLicense`, `Set-AzureADUserLicense`, `Update-MgUser`, and Graph equivalents (`New-Mg*`, `Update-Mg*`, `Remove-Mg*`) — **including** `Remove-MgGroupMemberByRef` and `Remove-MgUserMemberOf`, since under group-based licensing a group-membership removal is itself a licence revocation.
   ```
   Set-\w+|New-\w+|Remove-\w+|Enable-\w+|Disable-\w+|Update-\w+
   ```
   filtered to Exchange/Graph-shaped cmdlet names, excluding any file whose path clearly marks it as onboarding/admin tooling.
2. **Interactive or delegated auth** in runtime code: `-Interactive`, `-DeviceCode`, `Connect-ExchangeOnline` without `-Certificate`/`-CertificateThumbprint`, `Connect-MgGraph` without `-CertificateThumbprint`.
3. **Secret-shaped literals**: strings that look like client secrets, connection strings, tokens, or certificate material (`AccountKey=`, `-----BEGIN`, long base64 blobs assigned to a variable named like `secret`/`key`/`token`/`password`).

Report every match with file and line. A clean scan on this repo today is expected — there's no runtime code yet — so an empty result is a pass, not a sign the scan didn't run.
