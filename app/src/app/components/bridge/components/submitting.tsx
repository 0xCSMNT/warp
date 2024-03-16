export function Submitting() {
  return (
    <div className="bg-black flex flex-row rounded-xl h-full justify-center items-end p-10 gap-6">
      <iframe
        src="https://giphy.com/embed/MaThe6p8WAKbf9NDDM"
        width="200px"
        height="200px"
        className="giphy-embed"
        allowFullScreen
      ></iframe>
      <div>
        <div className="text-white font-extralight text-lg">{`Base -> Arbitrum`}</div>
        <div className="text-white font-medium text-lg">{`100 USDC -> 100 Real Yield USDC`}</div>
      </div>
    </div>
  )
}
