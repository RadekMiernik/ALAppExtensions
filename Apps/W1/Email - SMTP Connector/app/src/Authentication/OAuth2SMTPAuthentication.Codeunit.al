codeunit 4516 "OAuth2 SMTP Authentication" implements "SMTP Authentication"
{
    Access = Internal;

    var
        NoOAuth2ProviderErr: Label 'No extension provided the OAuth 2.0 authentication.';
        CouldNotAuthenticateErr: Label 'Could not authenticate. To resolve the problem, choose the Authenticate action on the SMTP Account page.';
        AuthenticationSuccessfulMsg: Label '%1 was authenticated.', Comment = '%1 - user email, for example, admin@domain.com';
        AuthenticationFailedMsg: Label 'Could not authenticate.';
        
    procedure Validate(var SMTPAccount: Record "SMTP Account");
    begin
        // do nothing
    end;

    [NonDebuggable]
    procedure Authenticate(SmtpClient: DotNet SmtpClient; SMTPAccount: Record "SMTP Account");
    var
        SMTPConnectorImpl: Codeunit "SMTP Connector Impl.";
        DotNetSaslMechanismOAuth2: DotNet SaslMechanismOAuth2;
        CancellationToken: DotNet CancellationToken;
        AccessToken: Text;
        UserName: Text;
    begin
        // Implement the OAuth 2.0 authentication for SMTP Setup in an Exchange Online mailbox is used.
        if SMTPAccount.Server = SMTPConnectorImpl.GetO365SmtpServer() then
            GetOAuth2Credentials(UserName, AccessToken)
        else
            OnSMTPOAuth2Authenticate(UserName, AccessToken, SMTPAccount.Server);

        if AccessToken = '' then
            Error(NoOAuth2ProviderErr);

        DotNetSaslMechanismOAuth2 := DotNetSaslMechanismOAuth2.SaslMechanismOAuth2(UserName, AccessToken);
        SmtpClient.Authenticate(DotNetSaslMechanismOAuth2, CancellationToken);
    end;

    /// <summary>
    /// Provide the credentials to authenticate using OAuth 2.0 for Exchange Online mailboxes.
    /// </summary>
    /// <param name="UserName">Authentication user name for SMTP client. Email address of the user who is attempting to authenticate.</param>
    /// <param name="AccessToken">Acquired access token for SMTP client.</param>
    [NonDebuggable]
    internal procedure GetOAuth2Credentials(var UserName: Text; var AccessToken: Text)
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
    begin
        AccessToken := AzureAdMgt.GetAccessToken(AzureADMgt.GetO365Resource(), AzureADMgt.GetO365ResourceName(), true);
        if AccessToken = '' then
            Error(CouldNotAuthenticateErr);
        GetUserName(AccessToken, UserName);
    end;

    /// <summary>
    /// Authenticate the current user.
    /// Disregard the token cache and show the authentication dialog.
    /// </summary>
    [NonDebuggable]
    internal procedure AuthenticateWithOAuth2()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        AzureADAccessDialog: Page "Azure AD Access Dialog";
        AuthorizationCode: Text;
        AccessToken: Text;
    begin
        AuthorizationCode := AzureADAccessDialog.GetAuthorizationCode(AzureADMgt.GetO365Resource(), AzureADMgt.GetO365ResourceName());
        if AuthorizationCode <> '' then
            AccessToken := AzureAdMgt.AcquireTokenByAuthorizationCode(AuthorizationCode, AzureADMgt.GetO365Resource());
    end;

    /// <summary>
    /// Verify if the current user is successfully authenticated.
    /// If there is token cache, it will be used. Otherwise, the authentication dialog will be shown.
    /// </summary>
    [NonDebuggable]
    internal procedure CheckOAuth2Authentication()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        UserName: Text;
        AccessToken: Text;
    begin
        AccessToken := AzureAdMgt.GetAccessToken(AzureADMgt.GetO365Resource(), AzureADMgt.GetO365ResourceName(), true);
        if AccessToken <> '' then begin
            GetUserName(AccessToken, UserName);
            Message(AuthenticationSuccessfulMsg, UserName);
        end else
            Message(AuthenticationFailedMsg);
    end;

    /// <summary>
    /// Get user's email address by the access token.
    /// </summary>
    /// <param name="AccessToken">The access token for outlook.office.com</param>
    /// <param name="UserName">The email address of the user for whom the access token got acquired.</param>
    [NonDebuggable]
    [TryFunction]
    internal procedure GetUserName(AccessToken: Text; var UserName: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        AccessTokenSections: List of [Text];
        AccessTokenBodyEncoded: Text;
        AccessTokenBodyDecoded: Text;
        JObject: JsonObject;
        JToken: JsonToken;
    begin
        // Access token consists of a header, body and signature
        AccessTokenSections := AccessToken.split('.');

        // Get the encoded body
        AccessTokenBodyEncoded := AccessTokenSections.Get(2);

        // Base64 encoded string should always have a length that is a multiple of 4
        while StrLen(AccessTokenBodyEncoded) mod 4 > 0 do
            AccessTokenBodyEncoded += '=';

        AccessTokenBodyDecoded := Base64Convert.FromBase64(AccessTokenBodyEncoded);
        JObject.ReadFrom(AccessTokenBodyDecoded);
        JObject.Get('unique_name', JToken);
        UserName := JToken.AsValue().AsText();
    end;

    /// <summary>
    /// Provide the credentials for SMTP Setup to authenticate using OAuth 2.0.
    /// </summary>
    /// <param name="UserName">Authentication user name for SMTP client. Email address of the user who is attempting to authenticate.</param>
    /// <param name="AccessToken">Acquired access token for SMTP client.</param>
    /// <param name="SMTPServer">The SMTP server of the SMTP setup.</param>
    [IntegrationEvent(false, false)]
    [NonDebuggable]
    local procedure OnSMTPOAuth2Authenticate(var UserName: Text; var AccessToken: Text; SMTPServer: Text)
    begin
    end;
}
