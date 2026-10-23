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
    Write-Host "`n===== $user =====" -ForegroundColor Cyan

    aws iam list-access-keys `
        --user-name $user `
        --query "AccessKeyMetadata[].{AccessKeyId:AccessKeyId,Status:Status,Created:CreateDate}" `
        --output table
}