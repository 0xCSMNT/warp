import Image from "next/image"

interface InputProps {
  amountUsd: string
  isLoading: boolean
  value: string
  onChange: (value: string) => void
}

export function Input(props: InputProps) {
  const { isLoading } = props
  return (
    <div className="flex flex-col bg-element rounded-xl w-full p-4 gap-4">
      <div className="flex flew-row justify-between items-center">
        <div>
          <input
            className="peer w-full h-full bg-transparent text-white font-sans font-normal outline-0 focus:outline-0 transition-all placeholder-shown:border placeholder-shown:border-blue-gray-200 placeholder-shown:border-t-blue-gray-200 border border-transparent focus:border-t-transparent text-4xl  [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
            placeholder="0"
            onChange={(e) => props.onChange(e.target.value)}
            type="number"
            value={props.value}
          />
        </div>
        <div className="flex flex-row gap-2 items-center text-lg font-medium text-white bg-element2 px-4 py-2 rounded-full">
          <Image
            alt="arbitrum logo"
            src="/assets/usdc-logo.svg"
            width={24}
            height={24}
          />
          <div>USDC</div>
        </div>
      </div>
      <div className="flex flew-row justify-between items-end">
        <div className="text-base text-[#9B9B9B]">{props.amountUsd}</div>
        {isLoading && (
          <div className="h-3 w-3">
            <span className="animate-ping absolute inline-flex h-3 w-3 rounded-full bg-white opacity-75"></span>
          </div>
        )}
      </div>
    </div>
  )
}
