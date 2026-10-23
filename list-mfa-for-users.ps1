$users = @(
    "dev-alice",
    "dev-bob",
    "dev-charlie",
    "dev-david",
    "fin-emma",
    "fin-frank",
    "op-george",
    "op-henry",
    "op-irene"
)

foreach ($user in $users) {
    $mfa = aws iam list-mfa-devices --user-name $user --query "MFADevices[].SerialNumber" --output text

    if ($mfa) {
        Write-Host "$user : MFA CONFIGURED"
    } else {
        Write-Host "$user : NO MFA"
    }
}