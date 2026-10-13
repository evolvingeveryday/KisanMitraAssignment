# CS543 — Assignment 3: Integrate an External SOAP Partner
## Kisan Mitra Platform

**Team Members:**
- **Dipesh Mishra** — 20251651036
- **Suraj Ku. Saw** — 20251651092
- **Sandeep Parmar** — 20251651081
- **Vivek Kumar** — 20251651104

**Service:** Kisan Mitra Payment Integration Edge (**KisanPay Gateway**)

---

## 1. Context & SOAP Justification (Task 1)

Kisan Mitra is built as a REST-oriented microservices platform for consumer-facing operations (Catalogue, Orders, User Profiles). However, for processing payments with financial institutions and rural cooperative banks, Kisan Mitra integrates with an external banking partner, **KisanPay Gateway** (`http://kisanpay.gov.in/ws/payment`), via a **SOAP/WSDL** interface.

We deliberately chose SOAP for this banking edge rather than REST for three reasons:
1. **Strict, Strongly-Typed Contract:** Banking settlements involve non-negotiable legal and financial payloads. The WSDL document and associated XML Schema enforce schema validation at the protocol boundary before requests reach business logic.
2. **Message-Level Security (WS-Security):** Unlike transport-layer TLS (which terminates at intermediary proxies and load balancers), SOAP supports message-level encryption and digital signing (`<soapenv:Header>`), ensuring non-repudiation between rural banking clearinghouses and Kisan Mitra.
3. **Transaction ACID Guarantees:** Banking protocols require deterministic two-phase commit coordination and standardized fault propagation (`soap:Fault`), preventing money from being debited without synchronous settlement receipts.

The single operation integrated is `processPayment`.

---

## 2. Partner Contract (Task 2)

The complete WSDL 1.1 specification is located in `partner.wsdl`. It defines all six required elements:
- `wsdl:types`: XML Schema defining `PartnerCredentials`, `ProcessPaymentRequest`, `ProcessPaymentResponse`, and `PaymentFaultDetail`.
- `wsdl:message`: `PartnerHeaderMessage`, `ProcessPaymentRequestMessage`, `ProcessPaymentResponseMessage`, and `PaymentFaultMessage`.
- `wsdl:portType`: `KisanPayPortType` declaring the `processPayment` operation.
- `wsdl:binding`: `KisanPaySoapBinding` binding the portType to SOAP 1.1 Document/Literal over HTTP.
- `wsdl:service`: `KisanPayGatewayService`.
- `wsdl:port`: `KisanPayPort` with target address `https://api.kisanpay.gov.in/ws/v1/gateway`.

---

## 3. Hand-Crafted SOAP Messages (Task 3)

The hand-formed messages matching the WSDL element-for-element are saved in:
- `soap-request.xml`: Contains authentication credentials in `<soapenv:Header>` and the payment parameters (`orderId`, `amount`, `payerKisanId`, `paymentMethod`) in `<soapenv:Body>`.
- `soap-response.xml`: Returns the confirmation receipt (`referenceNumber`, `settledAmount`, `status: SETTLED`, `processedAt`).
- `soap-fault.xml`: Returns a standard failure with `<faultcode>soapenv:Client.PaymentDeclined</faultcode>` and detailed `<pay:PaymentFaultDetail>`.

---

## 4. HTTP Binding (Task 4)

Below is the HTTP POST request carrying the payment message:

```http
POST /ws/v1/gateway HTTP/1.1
Host: api.kisanpay.gov.in
Content-Type: text/xml; charset=utf-8
Content-Length: 672
SOAPAction: "http://kisanpay.gov.in/ws/payment/processPayment"

<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                  xmlns:pay="http://kisanpay.gov.in/ws/payment">
  <soapenv:Header>
    <pay:PartnerCredentials>
      <pay:merchantId>KM-MERCHANT-8821</pay:merchantId>
      <pay:apiKey>sec_live_kisan_mitra_99a8b7c6d5e4f3</pay:apiKey>
      <pay:timestamp>2026-10-13T20:30:00Z</pay:timestamp>
    </pay:PartnerCredentials>
  </soapenv:Header>
  <soapenv:Body>
    <pay:ProcessPaymentRequest>
      <pay:transactionId>TXN-KM-20261013-0091</pay:transactionId>
      <pay:orderId>ORD-5542</pay:orderId>
      <pay:payerKisanId>BUYER-GUJ-90214</pay:payerKisanId>
      <pay:amount>1450.00</pay:amount>
      <pay:currency>INR</pay:currency>
      <pay:paymentMethod>UPI</pay:paymentMethod>
    </pay:ProcessPaymentRequest>
  </soapenv:Body>
</soapenv:Envelope>
```

---

## 5. Discovery — Modern Catalogue Registry Entry (Task 5)

Instead of running an obsolete UDDI server, Kisan Mitra discovers the partner contract via an enterprise service catalog registry entry (RESTful API Catalog / tModel pointer):

```json
{
  "business": {
    "businessKey": "org.gov.in.kisanpay",
    "name": "National Agricultural Payments Corporation (KisanPay)",
    "description": "Rural electronic settlement gateway for agricultural produce transactions",
    "contact": "integration-support@kisanpay.gov.in"
  },
  "service": {
    "serviceKey": "srv.kisanpay.gateway.v1",
    "name": "KisanPay Direct Settlement Service",
    "category": "payment-gateway",
    "environment": "production",
    "endpoint": "https://api.kisanpay.gov.in/ws/v1/gateway"
  },
  "binding": {
    "protocol": "SOAP-1.1-OVER-HTTP",
    "transport": "http://schemas.xmlsoap.org/soap/http",
    "wsdlUri": "https://api.kisanpay.gov.in/contracts/v1/kisanpay.wsdl",
    "tModelFingerprint": "urn:kisanpay:spec:payment:v1:document-literal",
    "schemaValidation": true
  }
}
```

Kisan Mitra's deployment pipeline fetches the WSDL from `wsdlUri` during CI/CD build time to generate typed request stubs.

---

## 6. Fault Mapping (Task 6)

When the partner returns a SOAP fault, Kisan Mitra intercepts the XML error and maps it into our internal domain error model (`placeOrder` contract from Assignment 2) so that technical partner details never leak to our buyers or farmers:

| Partner SOAP Fault Code | Partner Fault Detail Reason | Kisan Mitra Domain Response (`placeOrder`) | HTTP Status Code | Leaked Detail Prevented |
|---|---|---|---|---|
| `soapenv:Client.PaymentDeclined` | `KPAY_ERR_INSUFFICIENT_FUNDS`: Buyer account balance is lower than transaction amount | `title: "Payment Declined"`, `detail: "The transaction was declined by your payment provider. Please verify funds and retry."` | `409 Conflict` (or `422 Unprocessable`) | Hides internal bank error codes, partner clearing account details, and backend routing numbers. |
| `soapenv:Client.AuthenticationFailed` | `KPAY_ERR_INVALID_APIKEY`: Merchant credential revoked or expired | `title: "Payment Gateway Error"`, `detail: "Unable to process payment due to an upstream gateway error. Please try again later."` | `502 Bad Gateway` | Prevents exposing merchant API keys, partner system messages, or credential failures. |
| `soapenv:Server.Timeout` | `KPAY_ERR_CORE_BANKING_UNAVAILABLE`: Partner banking switch unreachable | `title: "Payment Gateway Unavailable"`, `detail: "Banking switch is currently undergoing maintenance. Order saved as PENDING_PAYMENT."` | `503 Service Unavailable` | Prevents exposing server stack traces and private gateway hostnames. |
