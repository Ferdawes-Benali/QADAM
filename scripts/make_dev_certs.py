"""Create a local CA + server certificate (for HTTPS on the hub and MQTT over TLS 1.3). Development/demo only.

  python scripts/make_dev_certs.py --ip 192.168.43.10 --ip 127.0.0.1
  python -m qadam_hub --ssl-keyfile ../certs/server.key --ssl-certfile ../certs/server.pem   (run from hub/)
"""
import argparse
import datetime as dt
import ipaddress
from pathlib import Path

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.x509.oid import NameOID


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ip", action="append", default=[])
    ap.add_argument("--dns", action="append", default=["localhost"])
    ap.add_argument("--out", default="certs")
    a = ap.parse_args()
    out = Path(a.out)
    out.mkdir(exist_ok=True)
    now = dt.datetime.now(dt.timezone.utc)
    ca_key = ec.generate_private_key(ec.SECP256R1())
    ca_name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "Qadam Dev CA")])
    ca = (x509.CertificateBuilder().subject_name(ca_name).issuer_name(ca_name).public_key(ca_key.public_key())
          .serial_number(x509.random_serial_number()).not_valid_before(now).not_valid_after(now + dt.timedelta(days=365))
          .add_extension(x509.BasicConstraints(ca=True, path_length=0), critical=True).sign(ca_key, hashes.SHA256()))
    key = ec.generate_private_key(ec.SECP256R1())
    sans = [x509.DNSName(d) for d in a.dns] + [x509.IPAddress(ipaddress.ip_address(i)) for i in (a.ip or ["127.0.0.1"])]
    cert = (x509.CertificateBuilder().subject_name(x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "qadam-hub")]))
            .issuer_name(ca_name).public_key(key.public_key()).serial_number(x509.random_serial_number())
            .not_valid_before(now).not_valid_after(now + dt.timedelta(days=180))
            .add_extension(x509.SubjectAlternativeName(sans), critical=False).sign(ca_key, hashes.SHA256()))
    (out / "ca.pem").write_bytes(ca.public_bytes(serialization.Encoding.PEM))
    (out / "server.pem").write_bytes(cert.public_bytes(serialization.Encoding.PEM))
    (out / "server.key").write_bytes(key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                                       serialization.NoEncryption()))
    print(f"wrote {out}/ca.pem, server.pem, server.key (SAN: {', '.join(map(str, sans))})")


if __name__ == "__main__":
    main()
