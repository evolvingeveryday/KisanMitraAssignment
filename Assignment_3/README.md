# CS543 — Assignment 3: Integrate External SOAP Partner

## Team Members
- **Dipesh Mishra** — 20251651036
- **Suraj Ku. Saw** — 20251651092
- **Sandeep Parmar** — 20251651081
- **Vivek Kumar** — 20251651104

This folder contains the complete deliverables for Assignment 3 for the Kisan Mitra project.

## Deliverables
- `integration.md`: Contains the SOAP Context justification, HTTP binding block, Modern Registry entry, and Fault Mapping table.
- `partner.wsdl`: The complete WSDL 1.1 definition for the KisanPay Gateway service with all six required elements.
- `soap-request.xml`: Hand-formed request envelope with `<soapenv:Header>` credentials and `<soapenv:Body>`.
- `soap-response.xml`: Hand-formed response envelope with settled payment receipt.
- `soap-fault.xml`: Hand-formed fault envelope with `<faultcode>`, `<faultstring>`, and `<pay:PaymentFaultDetail>`.
