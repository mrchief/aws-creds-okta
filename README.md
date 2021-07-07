# aws-creds-okta

Obtain temporary AWS Creds from your Okta Profile.

## Usage

Here's an example. All options are required except `okta_mfa_method` which default to TOTP based notification.

```yaml
- name: Get AWS Credentials
  uses: mrchief/aws-creds-okta@master # or a tagged release version
  with:
    aws_role_arn: arn:aws:iam::account-id:role/role-name
    okta_username: okta.user@mycompany.com
    okta_password: ${{ secrets.OKTA_PASSWORD }}
    okta_app_url: https://mycompany.okta.com/home/amazon_aws/1234567890abcdefghij/123
    okta_mfa_seed: ${{ secrets.OKTA_MFA_SEED }}
```

Once this step runs it'll set the following environment variables for subsequent steps:

```shell
AWS_ACCESS_KEY_ID: ***
AWS_SECRET_ACCESS_KEY: ***
AWS_SESSION_TOKEN: ***
```

It also masks the actual values in the logs for added security.

### 💡 Note

- Currently only supports `totp` authentication. There are plans to add support for other MFA methods. PRs welcome.
- `okta_app_url` can be obtained by right clicking the Okta tile for you AWS account. This setup allows for federated login to different AWS accounts.
- `okta_password` & `okta_mfa_seed` can be set via environment variables `${{ env.OKTA_MFA_SEED }}` although it is not recommended to do so as it can leak secrets. Github repo secrets are the easiest way but if you manage secrets via some other mechanism, you can also use them - these are just normal inputs, you can pass them anything.
- If you run this action multiple times, you will receive new credentials each time, even if you specify the same role arn. This is because we cannot create an aws config or credentials file from the action that is accessible in the workflow. This also means we cannot support profiles.

## Can I use this

You can use this if you're doing **all** of this:

- you are using Okta for federated logins to AWS accounts
- you have setup Okta MFA with `TOTP` option (use a time based code, similar to Google Authenticator)
- have one or more AWS apps setup in your Okta apps (see screenshot)
  ![image](https://user-images.githubusercontent.com/781818/76578920-ae4c4380-64a0-11ea-8aaf-2eb41085e3af.png)

## How this works

This action uses [tokendito](https://github.com/dowjones/tokendito) tool to generate temporary AWS credentials. The credentials are generated in the home directory of the container and are then exported as environment variables so the subsequent steps can use them seamlessly.

It uses [mintotp](https://pypi.org/project/mintotp/) to generate a `totp`.

## Contributing

We welcome all kind of contributions, as long as they are not violating our Code of Conduct. You can contribute by:

- reporting a bug ([submit one here](https://github.com/mrchief/aws-creds-okta/issues))
- proposing new feature ([submit one here](https://github.com/mrchief/aws-creds-okta/issues))
- submitting new features or bug fixes ([send a PR](#sending-a-pr))

By contributing, you agree that your contributions will be licensed under the project's [license](#license)

### Sending a PR

We use [Github Flow](https://guides.github.com/introduction/flow/index.html) method so please follow these steps:

- Fork the repo and create your branch from master.
- If you've added code that should be tested, add tests.
- If you've changed APIs, update the documentation.
- Issue that pull request!

NOTE: Ensure that you merge the latest from "upstream" before making a pull request!

## Code of Conduct

Please see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## License

This action is released under [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0). Docker container images built in this project include third party materials. See [THIRD_PARTY_NOTICE.md](THIRD_PARTY_NOTICE.md) for details.
