import { useBridge } from "@/app/providers/bridge-provider"

import { Input } from "./input"
import { Quote } from "./quote"

export function Withdraw() {
  const {
    inputAmount,
    inputAmountUsd,
    isApproved,
    isApproving,
    isLoading,
    isSubmitting,
    quote,
    onApprove,
    onChangeInput,
    onSubmit,
  } = useBridge()
  return (
    <>
      <div>
        <Input
          onChange={onChangeInput}
          isLoading={isLoading}
          value={inputAmount}
          amountUsd={inputAmountUsd}
        />
      </div>
      {!isLoading && quote && (
        <Quote amount={quote.outputAmount} amountUsd={quote.outputAmountUsd} />
      )}
      <div
        className="flex h-13 bg-element w-full items-center p-4 justify-center rounded-full text-xl font-base cursor-pointer text-white"
        onClick={onApprove}
      >
        {isApproving ? "Approving..." : isApproved ? "Approved" : "Approve"}
      </div>
      <div
        className="flex h-13 bg-highlight w-full items-center p-4 justify-center rounded-full text-xl font-base cursor-pointer"
        onClick={onSubmit}
      >
        {isSubmitting && (
          <div className="h-3 w-3 mr-4">
            <span className="animate-ping absolute inline-flex h-3 w-3 rounded-full bg-background opacity-75"></span>
          </div>
        )}
        <div className="text-background">
          {isSubmitting ? "Withdrawing..." : "Withdraw"}
        </div>
      </div>
    </>
  )
}
