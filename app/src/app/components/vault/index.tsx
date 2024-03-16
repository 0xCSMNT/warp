interface VaultProps {
  name: string
  provider: string
  apy: string
}

export function Vault() {
  return (
    <div className="bg-[#4361EE] flex items-start rounded-3xl shadow-lg h-60 w-60 relative cursor-pointer">
      <div className="absolute inset-0 bg-[#4361EE] rounded-lg blur" />
      <div className="relative px-6 py-4 shadow-inner rounded-3xl flex flex-col justify-between h-full">
        <div>
          <div className="font-light text-xs">Sommelier Finance</div>
          <div className="font-bold text-3xl">Real Yield USD</div>
        </div>
        <div className="flex flex-row justify-between items-start">
          <div className="flex flex-col items-start text-lg">
            <div className="font-light">APY</div>
            <div className="font-semibold">28.46%</div>
          </div>
          <div className="flex flex-col items-start text-lg">
            <div className="font-light">TVL</div>
            <div className="font-semibold">28.46%</div>
          </div>
        </div>
      </div>
    </div>
  )
}