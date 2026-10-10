import QtQuick
import QtTest
import "GcloudModel.js" as Gcloud

TestCase {
    name: "GcloudModel"

    function test_parse_accounts_data() {
        return [
            {
                tag: "none",
                text: "[]",
                want: []
            },
            {
                tag: "two",
                text: '[{"account":"a@x.io","status":""},{"account":"b@x.io","status":"ACTIVE"}]',
                want: [
                    {
                        account: "a@x.io",
                        status: ""
                    },
                    {
                        account: "b@x.io",
                        status: "ACTIVE"
                    }
                ]
            },
            {
                tag: "empty output",
                text: "",
                want: null
            },
            {
                tag: "not a list",
                text: '{"account":"a@x.io"}',
                want: null
            },
        ];
    }

    function test_parse_accounts(data) {
        compare(Gcloud.parseAccounts(data.text), data.want);
    }

    function test_active_account_data() {
        return [
            {
                tag: "none",
                accounts: [],
                want: ""
            },
            {
                tag: "first",
                accounts: [
                    {
                        account: "a@x.io",
                        status: "ACTIVE"
                    }
                ],
                want: "a@x.io"
            },
            {
                tag: "second",
                accounts: [
                    {
                        account: "a@x.io",
                        status: ""
                    },
                    {
                        account: "b@x.io",
                        status: "ACTIVE"
                    }
                ],
                want: "b@x.io"
            },
            {
                tag: "no active",
                accounts: [
                    {
                        account: "a@x.io",
                        status: ""
                    }
                ],
                want: ""
            },
        ];
    }

    function test_active_account(data) {
        verify(Gcloud.activeAccount(data.accounts) === data.want);
    }

    function test_token_data() {
        return [
            {
                tag: "ok",
                exitCode: 0,
                stderr: "",
                login: Gcloud.LOGIN,
                want: {
                    ok: true,
                    reason: ""
                }
            },
            {
                tag: "needs login",
                exitCode: 1,
                stderr: "ERROR: (gcloud.auth.print-access-token) Your current active account [a@x.io] does not have " + "any valid credentials\nPlease run:\n\n  $ gcloud auth login\n\nto obtain new credentials.\n",
                login: Gcloud.LOGIN,
                want: {
                    ok: false,
                    reason: "Your current active account [a@x.io] does not have any valid credentials"
                }
            },
            {
                tag: "timeout",
                exitCode: 124,
                stderr: "",
                login: Gcloud.LOGIN,
                want: null
            },
            {
                tag: "other error",
                exitCode: 1,
                stderr: "ERROR: (gcloud.auth.print-access-token) Network is unreachable\n",
                login: Gcloud.LOGIN,
                want: null
            },
            {
                tag: "adc missing",
                exitCode: 1,
                stderr: "ERROR: (gcloud.auth.application-default.print-access-token) Your default credentials were not " + "found. To set up Application Default Credentials, see " + "https://cloud.google.com/docs/authentication/external/set-up-adc for more information.\n",
                login: Gcloud.ADC_LOGIN,
                want: {
                    ok: false,
                    reason: "Your default credentials were not found. To set up Application Default Credentials, see " + "https://cloud.google.com/docs/authentication/external/set-up-adc for more information."
                }
            },
            {
                tag: "adc needs reauth",
                exitCode: 1,
                stderr: "ERROR: (gcloud.auth.application-default.print-access-token) Reauthentication is needed. " + "Please run `gcloud auth application-default login` to reauthenticate.\n",
                login: Gcloud.ADC_LOGIN,
                want: {
                    ok: false,
                    reason: "Reauthentication is needed. Please run `gcloud auth application-default login` to reauthenticate."
                }
            },
            {
                tag: "adc other error",
                exitCode: 1,
                stderr: "ERROR: (gcloud.auth.application-default.print-access-token) Network is unreachable\n",
                login: Gcloud.ADC_LOGIN,
                want: null
            },
        ];
    }

    function test_token(data) {
        compare(Gcloud.token(data.exitCode, data.stderr, data.login), data.want);
    }

    function test_logged_out_data() {
        return [
            {
                tag: "first check",
                prev: null,
                cur: {
                    active: "a",
                    ok: false
                },
                want: false
            },
            {
                tag: "stays in",
                prev: {
                    active: "a",
                    ok: true
                },
                cur: {
                    active: "a",
                    ok: true
                },
                want: false
            },
            {
                tag: "drops out",
                prev: {
                    active: "a",
                    ok: true
                },
                cur: {
                    active: "a",
                    ok: false
                },
                want: true
            },
            {
                tag: "switched to a lapsed account",
                prev: {
                    active: "a",
                    ok: true
                },
                cur: {
                    active: "b",
                    ok: false
                },
                want: false
            },
            {
                tag: "already out",
                prev: {
                    active: "a",
                    ok: false
                },
                cur: {
                    active: "a",
                    ok: false
                },
                want: false
            },
        ];
    }

    function test_logged_out(data) {
        verify(Gcloud.loggedOut(data.prev, data.cur) === data.want);
    }
}
