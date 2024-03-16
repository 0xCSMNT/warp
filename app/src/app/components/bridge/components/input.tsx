import Image from "next/image"

export function Input() {
  const isLoading = false
  return (
    <div className="flex flex-col bg-element rounded-xl w-full p-4 gap-6">
      <div className="flex flew-row justify-between items-start">
        <div></div>
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
        <div className="text-base text-[#9B9B9B]">$0</div>
        {isLoading && (
          <div className="h-2 w-2">
            <span className="animate-ping absolute inline-flex h-2 w-2 rounded-full bg-white opacity-75"></span>
          </div>
        )}
      </div>
    </div>
  )
}
