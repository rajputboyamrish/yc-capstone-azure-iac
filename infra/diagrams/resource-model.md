# Resource Model Diagram (Text Description)

You can replace this file with a real PNG diagram.

**Text version:**

  - Subscription
    - Resource Group: `yc-capstone-rg`
      - VNet: `yc-vnet`
        - Subnet: `web`
        - Subnet: `data`
      - Storage Account: hosts static website
      - Key Vault: secrets (`db-conn`)
      - Log Analytics workspace
      - (Optional) VM / App Service (from earlier labs)
