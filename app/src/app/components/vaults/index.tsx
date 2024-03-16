import { Vault } from "@/app/components/vault"

export function Vaults() {
  return (
    <div className="flex flex-row gap-10">
      <Vault
        name="Real Yield USD"
        provider="Sommelier Finance"
        apy="28.46%"
        styles={{ bg: "bg-[#4361EE]" }}
      />
      <Vault
        name="gUSDC"
        provider="Gains"
        apy="25.6%"
        styles={{ bg: "bg-[#4361EE]" }}
      />
      <Vault
        name="maUSDC"
        provider="Morpho"
        apy="19.27%"
        styles={{ bg: "bg-[#1D2760]" }}
      />
    </div>
  )
}
