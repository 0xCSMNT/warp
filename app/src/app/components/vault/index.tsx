import clsx from "clsx"
import Image from "next/image"

interface VaultProps {
  networkArbitrum: boolean
  name: string
  provider: string
  apy: string
  onClick: () => void
  styles: {
    bg: string
    text?: string
  }
}

export function Vault(props: VaultProps) {
  const { styles } = props
  return (
    <div
      className={clsx(
        "flex items-start rounded-3xl shadow-lg h-60 w-60 relative cursor-pointer",
        styles.bg,
        styles.text ?? "text-background",
      )}
      onClick={props.onClick}
    >
      <div className={clsx("absolute inset-0 rounded-lg blur", styles.bg)} />
      <div className="relative px-6 py-4 shadow-inner rounded-3xl flex flex-col justify-between h-full w-full">
        <div>
          <div className="font-light text-sm">{props.provider}</div>
          <div className="font-bold text-3xl">{props.name}</div>
        </div>
        <div className="flex flex-row justify-between items-end w-full">
          <div className="flex flex-col items-start text-lg">
            <div className="font-light">APY</div>
            <div className="font-semibold">{props.apy}</div>
          </div>
          {props.networkArbitrum ? (
            <Image
              alt="arbitrum logo"
              src="/assets/arbitrum-logo.svg"
              width={26}
              height={26}
            />
          ) : (
            <Image
              alt="ethereum logo"
              src="/assets/ethereum-logo.png"
              width={16}
              height={16}
            />
          )}
        </div>
      </div>
    </div>
  )
}
