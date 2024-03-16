import { Vault } from "@/app/components/vault"

export function Vaults() {
  return (
    <div className="flex flex-row gap-10">
      <Vault
        name="Real Yield USD"
        provider="Sommelier Finance"
        apy="38.96%"
        styles={{ bg: "bg-[#4361EE]", text: "text-white" }}
      />
      <Vault
        name="gUSDC"
        provider="Gains"
        apy="25.6%"
        styles={{ bg: "bg-[#3A0CA3]", text: "text-white" }}
      />
      <Vault
        name="maUSDC"
        provider="Morpho"
        apy="19.27%"
        styles={{ bg: "bg-[#1D2760]", text: "text-white" }}
      />
    </div>
  )
}
