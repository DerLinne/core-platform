# Protect your Services by using the OAuth Proxy

You can add a transparent SSO Check in front of your Ingress published Service on the Kuberntes Cluster.

We use the (OAuth2 Proxy)[https://github.com/oauth2-proxy/oauth2-proxy] to do this.

A preconfigured instance is running at https://oauth.{DOMAIN} and can be used, by adding the following annotations to yours services ingress definition.

```
    nginx.ingress.kubernetes.io/auth-url: "https://oauth.{{ default.GENERAL_DOMAIN_NAME }}/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://oauth.{{ default.GENERAL_DOMAIN_NAME }}/oauth2/start?rd=https://$host$request_uri"
    nginx.ingress.kubernetes.io/auth-response-headers: X-Auth-Request-User,X-Auth-Request-Email
```

After that, redeploy the service and you will be asked for a working credentials from keycloak.