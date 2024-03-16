interface VaultProps {
  name: string
  provider: string
  apy: string
}

export function Vault() {
  return (
    <div className="bg-[#4361EE] flex flex-col justify-between items-start rounded-3xl p-5 shadow-lg h-60 w-60">
      <div>
        <div className="font-light text-xs">Sommelier Finance</div>
        <div className="font-bold text-3xl">Real Yield USD</div>
      </div>
      <div className="flex flex-row justify-between items-start">
        <div className="flex flex-col items-start text-2xl">
          <div className="font-light">APY</div>
          <div className="font-semibold">28.46%</div>
        </div>
        {/* <div>10</div> */}
      </div>
    </div>
  )
}

// export function Vault() {
//   return (
//     <div className="rounded-lg p-6 bg-white shadow-inner blur-md">
//       <div className="rounded-lg bg-blue-500 ring-4 ring-blue-400 ring-opacity-50 p-4"></div>
//     </div>
//   )
// }
