interface QuoteProps {
  amount: string
  amountUsd: string
}

export function Quote(props: QuoteProps) {
  return (
    <div className="flex flex-col bg-element rounded-xl w-full px-4 py-3">
      <div className="text-xl text-white">{props.amount} USDC</div>
      <div className="flex flew-row justify-between items-end">
        <div className="text-base text-[#9B9B9B]">{props.amountUsd}</div>
        <div className="text-base text-[#9B9B9B]">Receive</div>
      </div>
    </div>
  )
}
